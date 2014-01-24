web: bundle exec rackup config.ru -p $PORT
worker: bundle exec sidekiq -c 5 -r ./lib/workers.rb

