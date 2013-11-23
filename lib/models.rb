db = Sequel.connect(Evercam::Config[:database])
Sequel::Model.plugin :association_proxies
Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :boolean_readers
db.extension :pg_array

require_relative './models/device'
require_relative './models/stream'
require_relative './models/client'
require_relative './models/access_token'
require_relative './models/access_token_right'
require_relative './models/access_scope'
require_relative './models/user'

