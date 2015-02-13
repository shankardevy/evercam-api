# Copyright (c) 2014, Evercam.ip

require "active_support/all"
require "faraday"
require "logjam"
require "mutations"
require "pony"
require "3scale_client"
require "evercam_misc"
require "evercam_models"
require_relative "actors/camera_create"
require_relative "actors/camera_update"
require_relative "actors/password_reset"
require_relative "actors/share_create_common"
require_relative "actors/share_create"
require_relative "actors/share_create_for_request"
require_relative "actors/share_delete"
require_relative "actors/share_update"
require_relative "actors/snapshot_create"
require_relative "actors/snapshot_fetch"
require_relative "actors/token_set"
require_relative "actors/user_confirm"
require_relative "actors/user_reset"
require_relative "actors/user_signup"
require_relative "actors/user_update"
require_relative "actors/webhook_create"
require_relative "actors/webhook_update"
require_relative "actors/webhook_delete"
require_relative "actors/model_create"
require_relative "actors/model_update"
require_relative "actors/vendor_create"
require_relative "actors/mailers/mailer"
require_relative "actors/mailers/account_mailer"
require_relative "actors/mailers/user_mailer"

module Evercam
  VALID_IP_ADDRESS_REGEX = Regexp.new('^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$');
  VALID_HOSTNAME_REGEX   = Regexp.new('^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$');

  include WebErrors
end
