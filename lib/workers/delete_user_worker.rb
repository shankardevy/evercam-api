require_relative "../../app/api/v1/helpers/cache_helper.rb"

module Evercam
  class DeleteUserWorker
    include Sidekiq::Worker
    include Evercam::CacheHelper

    def perform(username)
      begin
        user = ::User.by_login(username)
        raise NotFoundError, 'user does not exist' unless user

        query = Camera.where(owner: user)
        query.eager(:owner).all.select do |camera|
          invalidate_for_camera(camera.exid)
          camera.destroy
        end

        invalidate_for_user(user.username)
        user.destroy
        logger.info("User (#{user.username}) delete successfully.")
      rescue => e
        logger.warn "User delete exception: #{e.message}"
      end
    end
  end
end
