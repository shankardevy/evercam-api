# Copyright (c) 2014, Evercam.ip

require "active_support/all"
require "faraday"
require "logjam"
require "mutations"
require "pony"
require "3scale_client"
require "evercam_misc"
require "evercam_models"
require "evercam_sidekiq"
require "actors/version"
require "actors/camera_create"
require "actors/camera_update"
require "actors/password_reset"
require "actors/share_create_common"
require "actors/share_create"
require "actors/share_create_for_request"
require "actors/share_delete"
require "actors/share_update"
require "actors/snapshot_create"
require "actors/snapshot_fetch"
require "actors/token_set"
require "actors/user_confirm"
require "actors/user_reset"
require "actors/user_signup"
require "actors/user_update"
require "actors/mailers/mailer"
require "actors/mailers/account_mailer"
require "actors/mailers/user_mailer"

module Evercam
  VALID_IP_ADDRESS_REGEX = Regexp.new('^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$');
  VALID_HOSTNAME_REGEX   = Regexp.new('^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$');

  include WebErrors
end
