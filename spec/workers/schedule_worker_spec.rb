require 'data_helper'

describe Evercam::ScheduleWorker do

  subject { Evercam::ScheduleWorker }

  before(:each) do
    subject.jobs.clear
    subject.enable
  end

  describe '#enable' do
    it 'creates a scheduled job for heartbeat' do
      expect(subject.jobs.size).to eq(1)
    end
  end

  describe '#disable' do
    it 'removes all schedule worker jobs from the queue' do
      job0 = mock(:delete)
      set0 = mock(select: [job0])

      Sidekiq::ScheduledSet.expects(:new).returns(set0)
      subject.disable
    end
  end

  describe '#execute' do
    it 'executes the workers for that frequency' do
      Evercam::HeartbeatWorker.expects(:run)
      subject.execute
    end
  end

  describe '#requeue' do
    it 'queues a new job for the same frequency' do
      subject.jobs.clear
      subject.requeue
      expect(subject.jobs.size).to eq(1)
    end
  end

end

