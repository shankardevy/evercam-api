require 'sequel'
Sequel.connect(ENV['DATABASE_URL'])

require 'bcrypt'
require_relative './models/user'

