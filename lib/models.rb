db = Sequel.connect(Evercam::Config[:database])
Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :boolean_readers

require_relative './models/device'
require_relative './models/stream'
require_relative './models/client'
require_relative './models/access_token'
require_relative './models/access_token_right'
require_relative './models/user'

