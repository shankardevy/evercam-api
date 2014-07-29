module Evercam
  class ScheduleWorker

    include Sidekiq::Worker
    sidekiq_options retry: false

    def self.enable
      disable # There can be only one
      requeue
    end

    def self.disable
      Sidekiq::ScheduledSet.new.
        select { |j| j.klass == self.name }.
        map(&:delete)
    end

    def self.execute
      HeartbeatWorker.run
    end

    def self.requeue
      perform_in(60 * 5)
    end

    def perform
      logger.info("Starting schedule worker")
      self.class.execute
      self.class.requeue
    end

  end
end

