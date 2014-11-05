require 'puma_worker_killer'

pwk_started = false

after_worker_boot do
  unless pwk_started
    pwk_started = true
    PumaWorkerKiller.config do |config|
      config.ram           = 512 # mb
      config.frequency     = 10 # seconds
      config.percent_usage = 0.95
    end
    PumaWorkerKiller.start
  end
end
