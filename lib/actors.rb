ValidIpAddressRegex = Regexp.new('^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$');
ValidHostnameRegex = Regexp.new('^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$');

require_relative './actors/user_signup'
require_relative './actors/user_confirm'
require_relative './actors/user_reset'
require_relative './actors/user_update'
require_relative './actors/camera_create'
require_relative './actors/camera_update'
require_relative './actors/camera_update'
require_relative './actors/token_set'
require_relative './actors/password_reset'
require_relative './actors/snapshot_fetch'
require_relative './actors/snapshot_create'
require_relative './actors/share_create'
require_relative './actors/share_delete'
