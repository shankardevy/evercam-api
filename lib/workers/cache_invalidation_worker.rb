require_relative './unique_worker'
require_relative '../../lib/services'
require_relative '../../app/api/v1/helpers/cache_helper'

module Evercam
  class CacheInvalidationWorker

    include Evercam::CacheHelper
    include Sidekiq::Worker

    sidekiq_options queue: :cache

    def self.enqueue(camera_exid)
      UniqueQueueWorker.enqueue_if_unique('cache', self, camera_exid)
    end

    def perform(camera_exid)
      begin
        invalidate_for_camera(camera_exid)
        logger.info("Invalidated cache for camera #{camera_exid}")
      rescue => e
        logger.warn "Cache Invalidation exception: #{e.message}"
      end
    end
  end
end
