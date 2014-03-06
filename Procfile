web: bundle exec rackup -s Puma -O Threads=0:5 config.ru -p $PORT
worker: bundle exec sidekiq -c 5 -r ./lib/workers.rb

