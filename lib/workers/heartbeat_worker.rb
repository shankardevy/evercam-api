require 'net/http'
require 'faraday'
require 'mini_magick'
require 'faraday/digestauth'
require 'dalli'
require 'curb'
require 'active_support'
require 'active_support/core_ext'
require 'concurrent/utilities'
require_relative './unique_worker'
require_relative '../../lib/services'
require_relative '../../app/api/v1/helpers/cache_helper'

module Evercam
  class HeartbeatWorker

    include Evercam::CacheHelper
    include Sidekiq::Worker

    sidekiq_options retry: 10
    sidekiq_options queue: :heartbeat

    TIMEOUT = 5

    def self.enqueue(queue, camera_exid)
      UniqueQueueWorker.enqueue_if_unique(queue, self, camera_exid)
    end

    def self.enqueue_all
      Camera.select(:exid).each do |camera|
        UniqueQueueWorker.enqueue_if_unique('heartbeat', self, camera.exid)
      end
    end

    def snap_request(camera, updates, instant)
      begin
        conn = Faraday.new(:url => camera.external_url) do |faraday|
          faraday.request :basic_auth, camera.cam_username, camera.cam_password
          faraday.request :digest, camera.cam_username, camera.cam_password
          faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP, because curl crashes on Heroku
          faraday.options.timeout = 5           # open/read timeout in seconds
          faraday.options.open_timeout = 2      # connection open timeout in seconds
        end
        response = conn.get do |req|
          req.url camera.res_url('jpg')
        end
        if response.status == 401
          digest_response = Curl::Easy.new("#{camera.external_url}#{camera.res_url('jpg')}")
          digest_response.http_auth_types = :digest
          digest_response.username = camera.cam_username
          digest_response.password = camera.cam_password
          digest_response.perform

          _http_response, *http_headers = digest_response.header_str.split(/[\r\n]+/).map(&:strip)
          http_headers = Hash[http_headers.flat_map{ |s| s.scan(/^(\S+): (.+)/) }]

          response = OpenStruct.new({'status' => digest_response.response_code, 'body' => digest_response.body, 'headers' => http_headers})
        end

        if response.status == 200
          if response.headers.fetch('Content-Type', '').start_with?('image')
            image = MiniMagick::Image.read(response.body)

            filepath = "#{camera.exid}/snapshots/#{instant.to_i}.jpg"
            Evercam::Services.snapshot_bucket.objects.create(filepath, response.body)
            file = Evercam::Services.snapshot_bucket.objects[filepath]
            thumbnail_url = file.url_for(:get, {expires: 10.years.from_now, secure: true}).to_s

            Snapshot.create(
              camera: camera,
              created_at: instant,
              data: 'S3',
              notes: 'Evercam System'
            )
            image.resize "300x300"
            updates.merge!(is_online: true, last_online_at: instant, preview: image.to_blob, thumbnail_url: thumbnail_url)
          else
            logger.warn("Camera seems online, but returned content type: #{response.headers.fetch('Content-Type', '')}")
          end
        end
      rescue URI::InvalidURIError
        raise BadRequestError, 'Invalid URL'
      rescue Net::OpenTimeout
        # offline
      rescue Faraday::TimeoutError
        # offline
      rescue Faraday::ConnectionFailed
        # offline
      rescue => e
        # we weren't expecting this (famous last words)
        logger.error(e.message)
        logger.error(e.class)
        logger.error(e.backtrace.inspect)
      end
      updates
    end

    def perform(camera_exid)
      if [
        "carrollszoocam",
        "gpocam",
        "wayra-office",
        "wayra-agora",
        "wayrahikvision",
        "zipyard-navan-foh",
        "zipyard-ranelagh-foh",
        "ndrc-main",
        "ndrc-foodcam",
        "gemcon-cathalbrugha",
        "smartcity1",
        "stephens-green",
        "treacyconsulting1",
        "treacyconsulting2",
        "treacyconsulting3",
        "dcctestdumping1",
        "dcctestdumping2",
        "beefcam1",
        "beefcam2",
        "beefcammobile",
        "bennett"
      ].include? camera_exid
        Evercam::HeartbeatWorker.enqueue(camera_exid, camera_exid)
      else
        UniqueQueueWorker.enqueue_if_unique('heartbeat', Evercam::HeartbeatWorker, camera_exid)
      end
      begin
        Concurrent.timeout(30) do
          logger.info("Started update for camera #{camera_exid}")
          instant = Time.now
          camera = Camera.by_exid(camera_exid)
          return if camera.nil?
          updates = { is_online: false, last_polled_at: instant }

          unless camera.external_url.nil?
            updates = snap_request(camera, updates, instant)
          end
          if camera.is_online and not updates[:is_online]
            # Try one more time, some cameras are dumb
            updates = snap_request(camera, updates, instant)
            unless updates[:is_online]
              CameraActivity.create(
                camera: camera,
                access_token: nil,
                action: 'offline',
                done_at: Time.now,
                ip: nil
              )
            end
          end
          if not camera.is_online and updates[:is_online]
            CameraActivity.create(
              camera: camera,
              access_token: nil,
              action: 'online',
              done_at: Time.now,
              ip: nil
            )
          end
          camera_is_online = camera.is_online
          trigger_webhook(camera)
          camera.update(updates)
          cached_camera = Evercam::Services::dalli_cache.get(camera.exid)
          cached_thumbnail_url = cached_camera.blank? ? '' : cached_camera.thumbnail_url
          if camera_is_online == true || updates[:is_online] == true
            if (camera_is_online != updates[:is_online]) ||
                (thumbnail_token_time(cached_thumbnail_url) < thumbnail_token_time(camera.thumbnail_url) - 30.seconds)
              Evercam::Services.dalli_cache.set(camera_exid, camera, 0)
              CacheInvalidationWorker.enqueue(camera.exid)
            end
          end
          logger.info("Update for camera #{camera.exid} finished. New status #{updates[:is_online]}")
        end
      rescue Concurrent::TimeoutError
        # timeout
      end
    end

    def thumbnail_token_time(thumbnail_url)
      if thumbnail_url.blank?
        Time.now + 1.minutes
      else
        url = URI::parse(thumbnail_url).query
        token = CGI::parse(url)['Expires'].first.to_i
        Time.at(token) - 10.years
      end
    end

    def trigger_webhook(camera)
      webhooks = Webhook.where(camera_id: camera.id).all
      return if webhooks.empty?

      webhooks.each do |webhook|
        hook_conn = Faraday.new(:url => webhook.url) do |faraday|
          faraday.adapter Faraday.default_adapter
          faraday.options.timeout = 5
          faraday.options.open_timeout = 2
        end

        parameters = {
          id: camera.exid,
          last_polled_at: camera.last_polled_at,
          last_online_at: camera.last_online_at,
          is_online: camera.is_online
        }

        hook_conn.post '', parameters.to_s
      end
    end
  end
end
