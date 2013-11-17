require 'sequel'
conx = ENV['DATABASE_URL'] ||= 'postgres://localhost/evercam_dev'
Sequel.connect(conx)

require 'bcrypt'
require_relative './models/user'

