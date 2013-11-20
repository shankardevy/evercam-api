class Client < Sequel::Model

  plugin :after_initialize

  one_to_many :tokens, class: 'AccessToken', key: :grantee_id

  def self.by_exid(val)
    first(exid: val)
  end

  def after_initialize
    self.secret ||= SecureRandom.hex(16)
    self.exid ||= SecureRandom.hex(10)
    super
  end

  def default_callback_uri
    callback_uris.first
  end

  def allow_callback_uri?(val)
    callback_uris.any? do |uri|
      val[0, uri.length] == uri
    end
  end

end

