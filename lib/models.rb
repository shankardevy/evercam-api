require 'sequel'
Sequel.connect(ENV['DATABASE_URL'])

require_relative './models/user'

