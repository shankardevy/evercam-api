require 'simplecov'
require 'bundler'
require 'sequel'

sequel_connection = Sequel.connect(ENV['DATABASE_URL'])

Bundler.require(:default)
