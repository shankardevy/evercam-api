require_relative '../errors'

class Camera < Sequel::Model

  require 'georuby'
  include GeoRuby::SimpleFeatures

  many_to_one :vendor_model, class: 'VendorModel', key: :model_id
  one_to_many :endpoints, class: 'CameraEndpoint'
  many_to_one :owner, class: 'User', key: :owner_id
  one_to_many :activities, class: 'CameraActivity'
  one_to_many :snapshots, class: 'Snapshot'
  one_to_many :shares, class: 'CameraShare'

  MAC_ADDRESS_PATTERN = /^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$/i
  DEFAULT_RANGE = 1

  # Finds the camera with a matching external id
  # (exid) string or nil if none exists
  def self.by_exid(exid)
    first(exid: exid)
  end

  # Like by_exid but will raise an Evercam::NotFoundError
  # if the camera does not exist
  def self.by_exid!(exid)
    by_exid(exid) || (
      raise Evercam::NotFoundError, 'Camera does not exist')
  end

  # Returns the model for this camera using any specifically
  # set before trying to infer vendor from the mac address
  def vendor_model
    definite = super
    return definite if definite
    if mac_address
      if vendor = Vendor.by_mac(mac_address).first
        vendor.default_model
      end
    end
  end

  def vendor
    if vendor_model
      vendor_model.vendor
    end
  end

  # Determines if the presented token should be allowed
  # to conduct a particular action on this camera
  def allow?(right, token)
    AccessRightSet.for(self, token.nil? ? nil : token.target).allow?(right)
  end

  # The IANA standard timezone for this camera
  # defaulting to UTC if none specified
  def timezone
    Timezone::Zone.new zone:
      (values[:timezone] || 'Etc/UTC')
  end

  # Returns a deep merge of any config values set for this
  # camera with the config of any associated model
  def config
    fconf = vendor_model ? vendor_model.config : {}
    fconf.deep_merge(values[:config] || {})
  end

  # Returns the location for the camera as a GeoRuby
  # Point if it exists otherwise nil
  def location
    if super
      Point.from_hex_ewkb(super)
    end
  end

  def snapshot_by_ts(timestamp, range=nil)
    range ||= DEFAULT_RANGE
    if range < DEFAULT_RANGE then range = DEFAULT_RANGE end
    snapshots.order(:created_at).last(:created_at => (timestamp - range + 1).to_s...(timestamp + range).to_s)
  end

  def snapshot_by_ts!(timestamp, range=nil)
    snapshot_by_ts(timestamp, range)  || (
    raise Evercam::NotFoundError, 'Snapshot does not exist')
  end

  # Sets the cameras location as a GeoRuby Point
  # instance or call with nil to unset
  def location=(val)
    hex_ewkb =
      case val
      when Hash
        Point.from_x_y(
          val[:lng], val[:lat]
        ).as_hex_ewkb
      when Point
        val.as_hex_ewkb
      when nil
        nil
      end

    super(hex_ewkb)
  end

  def url
    "/users/#{owner.username}/cameras/#{exid}"
  end

  # Utility method to check whether a string is a potential MAC address.
  def self.is_mac_address?(text)
    !(MAC_ADDRESS_PATTERN =~ text).nil?
  end

  def external_url
    endpoints.find {|e| e.public?}
  end

  def internal_url
    endpoints.find {|e| !e.public?}
  end

  def jpg_url
    config.fetch('snapshots', {}).fetch('jpg', '')
  end

  def cam_username
    config.fetch('auth', {}).fetch('basic', {}).fetch('username', '')
  end

  def cam_password
    config.fetch('auth', {}).fetch('basic', {}).fetch('password', '')
  end

end

