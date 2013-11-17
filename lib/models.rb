require 'sequel'
Sequel.connect(Evercam::Config.database)

require 'bcrypt'
require_relative './models/user'

