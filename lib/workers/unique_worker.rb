class UniqueQueueWorker
  attr_reader :queue, :worker, :args

  def initialize(queue, worker, *args)
    @queue = queue
    @worker = worker
    @args = args
  end

  def self.enqueue_if_unique(queue, worker, *args)
    q = new(queue, worker, *args)
    q.enqueue unless q.exists?
  end

  def enqueue
    Sidekiq::Client.push({ 'queue' => queue, 'class' => worker, 'args' => args })
  end

  def exists?
    #OPTIMIZE: this is a O(N) operation, it should be optimized if it becomes a bottleneck
    #https://github.com/mperham/sidekiq/issues/2025#issuecomment-61182277
    Sidekiq::Queue.new(queue).any? do |job|
      job.klass == worker.to_s && job.args == args && job.queue == queue
    end
  end
end
