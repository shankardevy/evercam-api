require 'net/http'
require 'faraday'
require 'faraday/digestauth'
require 'socket'
require_relative '../actors/mailers/user_mailer'

module Evercam
  class EmailWorker

    include Sidekiq::Worker
    sidekiq_options retry: false

    TIMEOUT = 5

    def perform(params)
      camera = Camera.by_exid(params['camera'])
      user = User.by_login(params['user'])
      response = nil

      # Get image if needed
      if ['share_request', 'share'].include?(params['type']) and !camera.nil? && !camera.external_url.nil?
        begin
          conn = Faraday.new(:url => camera.external_url) do |faraday|
            faraday.request :basic_auth, camera.cam_username, camera.cam_password
            faraday.request :digest, camera.cam_username, camera.cam_password
            faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP, because curl crashes on Heroku
            faraday.options.timeout = 10           # open/read timeout in seconds
            faraday.options.open_timeout = 10      # connection open timeout in seconds
          end
          response = conn.get do |req|
            req.url camera.res_url('jpg')
          end
          if response.status == 200
            unless response.headers.fetch('content-type', '').start_with?('image')
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

      end
      add_snap = false
      unless response.nil?
        add_snap = true
      end

      if params['type'] == 'share_request'
        Mailers::UserMailer.share_request(user: user, email: params['email'], camera: camera,
                                        attachments: {'snapshot.jpg' => response.body},
                                        add_snap: add_snap, socket: Socket.gethostname)
      elsif params['type'] == 'share'
        Mailers::UserMailer.share(user: user, email: params['email'],
                                        camera:camera, key: params['key'],
                                        attachments: {'snapshot.jpg' => response.body}, add_snap: add_snap)
      end
    end

  end
end

