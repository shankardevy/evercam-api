module Evercam
  class DeleteUserWorker
    include Sidekiq::Worker

    def perform(user)
      begin
        # delete user owned cameras
        query = Camera.where(owner: user)
        query.eager(:owner).all.select do |camera|
          camera.destroy
        end

        user.destroy
        logger.info("User (#{user.username}) delete successfully.")
      rescue => e
        logger.warn "User delete exception: #{e.message}"
      end
    end
  end
end
