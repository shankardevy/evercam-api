require 'sequel'
Sequel.connect(Evercam::Config[:database])

require 'bcrypt'
require_relative './models/user'
require_relative './models/device'
require_relative './models/stream'

