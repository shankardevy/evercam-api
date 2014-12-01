module Evercam
  module SidekiqHelper
    def perform_in_background(queue, worker_class, id)
      Sidekiq::Client.push({
                             'queue' => queue,
                             'class' => worker_class,
                             'args' => [id]
                           })
    end
  end
end
