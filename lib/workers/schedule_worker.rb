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
      puts "Executing Heartbeat"
      HeartbeatWorker.run
    end

    def self.requeue
      puts "Rescheduling Heartbeat run at #{Time.now + (60 * 5)}"
      perform_in(60 * 5)
    end

    def perform
      logger.info("Starting schedule worker")
      self.class.execute
      self.class.requeue
    end

  end
end

