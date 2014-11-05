web: bundle exec puma -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-1} -p $PORT -e ${RACK_ENV:-development} -C ./config/puma.rb
worker: bundle exec sidekiq -c 5 -r ./scripts/sidekiq_setup.rb -C ./config/sidekiq.yml
