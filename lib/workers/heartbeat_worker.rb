class HeartBeatWorker
  include Sidekiq::Worker

  def perform(camera)
    puts camera
  end
end