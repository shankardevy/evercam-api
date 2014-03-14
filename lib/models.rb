require 'sequel'
require 'logger'
require_relative './config'

db = Sequel.connect(Evercam::Config[:database])
Sequel::Model.plugin :boolean_readers
Sequel::Model.plugin :association_proxies
Sequel::Model.plugin :timestamps, update_on_create: true
#db.loggers << Logger.new($stdout)

if :postgres == db.adapter_scheme
  db.extension :pg_array, :pg_json
end

require_relative './models/vendor'
require_relative './models/vendor_model'

require_relative './models/client'
require_relative './models/access_token'
require_relative './models/access_right'
require_relative './models/access_right_set'
require_relative './models/right_sets/camera_right_set'
require_relative './models/right_sets/snapshot_right_set'
require_relative './models/right_sets/account_right_set'

require_relative './models/user'
require_relative './models/country'

require_relative './models/camera'
require_relative './models/camera_endpoint'
require_relative './models/camera_activity'
require_relative './models/snapshot'
require_relative './models/camera_share'
