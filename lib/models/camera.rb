class Camera < Sequel::Model

  many_to_one :firmware
  one_to_many :endpoints, class: 'CameraEndpoint'
  many_to_one :owner, class: 'User'

  def self.by_exid(exid)
    first(exid: exid)
  end

  def allow?(right, token)
    return true if token &&
      token.owner == owner

    case right
    when :view
      return true if is_public?
      nil != token && (
        token.allow?("camera:view:#{exid}") ||
        token.allow?("cameras:view:#{owner.username}")
      )
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

