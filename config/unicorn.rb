worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 15
preload_app true
pid 'unicorn.pid'

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  Sequel::Model.db.disconnect if defined?(Sequel::Model.db)
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  Sequel::Model.db = Sequel.connect(Evercam::Config[:database])
  # Dalli cache
  options = { :namespace => "app_v1", :compress => true, :expires_in => 60*5 }
  if ENV["MEMCACHEDCLOUD_SERVERS"]
    Sidekiq::MEMCACHED = Dalli::Client.new(ENV["MEMCACHEDCLOUD_SERVERS"].split(','), :username => ENV["MEMCACHEDCLOUD_USERNAME"], :password => ENV["MEMCACHEDCLOUD_PASSWORD"])
  else
    Sidekiq::MEMCACHED = Dalli::Client.new('127.0.0.1:11211', options)
  end
end