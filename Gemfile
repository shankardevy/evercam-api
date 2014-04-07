source 'https://rubygems.org'
ruby '2.0.0'

gem 'puma'
gem 'rack'
gem 'rack-rewrite'
gem 'rack-ssl-enforcer',
  github: 'tobmatth/rack-ssl-enforcer'

gem 'rake'
gem 'sinatra'
gem 'json'

gem 'grape'
gem 'grape-entity'
gem 'grape-swagger', '0.7.2',
  github: 'tim-vandecasteele/grape-swagger'

gem 'newrelic_rpm'
gem 'newrelic-grape'

gem 'intercom', require: 'intercom'
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
gem 'evercam_models', '~> 0.0'
gem 'evercam_sidekiq', '~> 0.0'
gem 'evercam_actors', '~> 0.0'

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
  gem 'webmock', '1.15.2'
  gem 'rspec'
  gem 'guard-rspec'
  gem 'vcr'
  gem 'database_cleaner'

  gem 'mocha',
    require: 'mocha/api'
end
