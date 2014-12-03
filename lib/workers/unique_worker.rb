class UniqueQueueWorker
  attr_reader :queue, :worker, :args

  def initialize(queue, worker, *args)
    @queue = queue
    @worker = worker
    @args = args
  end

  def self.perform_async(queue, worker, *args)
    q = new(queue, worker, *args)
    q.enqueue unless q.exists?
  end

  def enqueue
    Sidekiq::Client.push({ 'queue' => queue, 'class' => worker, 'args' => args })
  end

  def exists?
    exists = false
    sidekiq_queue = Sidekiq::Queue.new(queue)
    sidekiq_queue.each do |job|
      if job.klass == worker.to_s && job.args == args
        exists = true
        break
      end
    end
    exists
  end
end
