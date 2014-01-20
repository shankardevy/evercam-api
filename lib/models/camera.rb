class Camera < Sequel::Model

  many_to_one :firmware
  one_to_many :permissions, class: 'CameraRight'
  one_to_many :endpoints, class: 'CameraEndpoint'
  many_to_one :owner, class: 'User'

  def self.by_exid(exid)
    first(exid: exid)
  end

  def has_right?(right, seeker)
    case seeker
    when User
      seeker == self.owner
    when AccessToken
      nil != permissions_dataset.
        first(token: seeker, name: right)
    else
      raise Evercam::AuthorizationError,
        'unknown permission seeker type'
    end
  end

  def timezone
    Timezone::Zone.new zone:
      (values[:timezone] || 'Etc/UTC')
  end

  def config
    fconf = firmware ? firmware.config : {}
    fconf.deep_merge(values[:config] || {})
  end

end

