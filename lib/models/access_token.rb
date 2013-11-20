class AccessToken < Sequel::Model

  plugin :after_initialize

  many_to_one :grantor, class: 'User'
  many_to_one :grantee, class: 'Client'

  def after_initialize
    self.request ||= SecureRandom.hex(16)
    self.expires_at ||= Time.now + 3600
    self.is_revoked = false
    super
  end

  def is_valid?
    false == is_revoked? &&
      Time.now <= self.expires_at
  end

end

