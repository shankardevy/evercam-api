class Client < Sequel::Model

  plugin :after_initialize

  one_to_many :tokens, class: 'AccessToken', key: :grantee_id

  def after_initialize
    self.secret ||= SecureRandom.hex(16)
    self.exid ||= SecureRandom.hex(10)
    super
  end

end

