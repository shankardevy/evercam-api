class Camera < Sequel::Model

  many_to_one :firmware
  one_to_many :endpoints, class: 'CameraEndpoint'
  many_to_one :owner, class: 'User'

  def self.by_exid(exid)
    first(exid: exid)
  end

  def allow?(right, auth)
    return true if auth == owner

    case right
    when :view
      is_public? || (nil != auth && (
        auth.scopes.include?("camera:view:#{exid}") ||
        auth.scopes.include?("cameras:view:all")
      ))
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

