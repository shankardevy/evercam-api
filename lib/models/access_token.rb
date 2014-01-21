class AccessToken < Sequel::Model

  plugin :after_initialize

  many_to_one :grantor, class: 'User'
  many_to_one :grantee, class: 'Client'

  def self.by_request(val)
    first(request: val)
  end

  def after_initialize
    self.request ||= SecureRandom.hex(16)
    self.expires_at ||= Time.now + 3600
    self.is_revoked ||= false
    super
  end

  def expires_in
    seconds = expires_at - Time.now
    seconds > 0 ? seconds.to_i : 0
  end

  def is_valid?
    false == is_revoked? &&
      Time.now <= self.expires_at
  end

  def scopes
    values[:scopes] ||= Sequel.pg_array([])
  end

end

