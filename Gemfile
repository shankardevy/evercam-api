source 'https://rubygems.org'
ruby '2.2.0'

gem 'unicorn'
gem 'rack'
gem 'rack-rewrite'
gem 'rack-ssl-enforcer',
  github: 'tobmatth/rack-ssl-enforcer'

gem 'rake'
gem 'sinatra'
gem 'json'
gem 'dalli'
gem 'kgio'
gem 'pony'
gem 'aws-sdk'
gem 'sidekiq'
gem 'mini_magick'
gem 'stringex'

gem 'grape'
gem 'grape-entity'
gem 'grape-swagger', '= 0.7.2'

gem 'activesupport-json_encoder',
  github: 'rails/activesupport-json_encoder'

gem 'faraday-digestauth', '~> 0.1.0',
  github: 'evercam/faraday-digestauth'

gem 'newrelic_rpm'
gem 'newrelic-grape'

gem 'intercom', '~> 2.1.1', require: 'intercom'
gem 'logjam'

gem 'mutations',
 github: 'garrettheaver/mutations'

gem 'rack-cors',
  require: 'rack/cors'

gem 'sinatra-flash',
  require: 'sinatra/flash'

gem 'sinatra-contrib',
  require: 'sinatra/contrib'

gem 'sinatra-partial',
  require: 'sinatra/partial'

gem 'evercam_misc', '~> 0.0'
gem 'evercam_models', '~> 0.3.10'

gem 'airbrake'

gem 'racksh'


group :development do
  gem 'fakes3'
  gem 'thin'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'pry-byebug'
end

group :test do
  gem 'minitest'
  gem 'simplecov'
  gem 'rack-test'
  gem 'factory_girl'
  gem 'nokogiri'
  gem 'webmock', '~> 1.17.0'
  gem 'rspec', '= 2.14.1'
  gem 'guard-rspec'
  gem 'guard-rack'
  gem 'database_cleaner'

  gem 'mocha',
    require: 'mocha/api'
end

