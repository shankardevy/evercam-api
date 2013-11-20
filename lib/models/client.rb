class Client < Sequel::Model

  def before_create
    self.exid ||= SecureRandom.hex(10)
    self.secret ||= SecureRandom.hex(10)
    super
  end

end

