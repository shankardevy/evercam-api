source 'https://rubygems.org'
ruby '2.1.2'

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

gem 'grape'
gem 'grape-entity'
gem 'grape-swagger', '0.7.2',
  github: 'tim-vandecasteele/grape-swagger'

gem 'faraday-digestauth', '~> 0.1.0',
  github: 'evercam/faraday-digestauth'

gem 'newrelic_rpm'
gem 'newrelic-grape'

gem 'intercom', '~> 2.0.0', require: 'intercom'
gem 'logjam'

gem 'mutations',
 github: 'garrettheaver/mutations'

gem 'rack-cors',
  require: 'rack/cors'

gem 'sinatra-flash',
  require: 'sinatra/flash'

gem 'sinatra-contrib',
  require: 'sinatra/contrib'  

gem 'sinatra-redirect-with-flash',
  require: 'sinatra/redirect_with_flash'

gem 'sinatra-partial',
  require: 'sinatra/partial'

gem 'sinatra-jsonp',
  require: 'sinatra/jsonp'

gem 'evercam_misc', '~> 0.0'
gem 'evercam_models', '~> 0.2.0'
gem 'evercam_sidekiq', '~> 0.1.0'
gem 'evercam_actors', '~> 0.2.0'

gem 'airbrake'

group :development do
  gem 'sqlite3'
  gem 'shotgun'
  gem 'thin'
end

group :test do
  gem 'simplecov'
  gem 'rack-test'
  gem 'factory_girl'
  gem 'nokogiri'
  gem 'webmock', '~> 1.17.0'
  gem 'rspec', '= 2.14.1'
  gem 'guard-rspec'
  gem 'database_cleaner'

  gem 'mocha',
    require: 'mocha/api'
end

