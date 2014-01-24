module Evercam
  class ScheduleWorker

    include Sidekiq::Worker
    sidekiq_options retry: false

    FREQS = {
      '1 minute' => 60,
      '1 hour' => 60 * 60,
      '1 day' => 60 * 60 * 24,
      '1 week' => 60 * 60 * 24 * 7
    }

    def self.enable
      FREQS.keys.each(&method(:requeue))
    end

    def self.disable
      Sidekiq::ScheduledSet.new.
        select { |j| j.klass == self.name }.
        map(&:delete)
    end

    def self.execute(freq)
      case freq
      when '1 minute'
        HeartbeatWorker.run
      end
    end

    def self.requeue(freq)
      perform_in(FREQS[freq], freq)
    end

    def perform(freq)
      self.class.execute(freq)
      self.class.requeue(freq)
    end

  end
end

