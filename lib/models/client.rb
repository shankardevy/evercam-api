class Client < Sequel::Model

  plugin :after_initialize

  one_to_many :tokens, class: 'AccessToken', key: :client_id

  def settings
    self[:settings] ? JSON.parse(self[:settings]) : {}
  end

  def settings=(hash)
  	self[:settings] = hash.to_json
  end

  def self.by_exid(val)
    first(exid: val)
  end

  def after_initialize
    self.secret ||= SecureRandom.hex(16)
    self.exid ||= SecureRandom.hex(10)
    super
  end

  def default_callback_uri
    callback_uris ? callback_uris.first : nil
  end

  def allow_callback_uri?(val)
    result = false
    if !val.nil?
      if !callback_uris.nil?
        result = callback_uris.any? {|uri| val[0, uri.length] == uri}
      else
        result = true
      end
    end
    result
  end

end

