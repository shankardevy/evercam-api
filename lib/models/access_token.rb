class AccessToken < Sequel::Model

  plugin :after_initialize

  many_to_one :user, key: :grantor_id
  many_to_one :client, key: :grantee_id

  def after_initialize
    self.request ||= SecureRandom.hex(16)
    self.expires_at ||= Time.now + 3600
    super
  end

end

