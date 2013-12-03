class Device < Sequel::Model

  many_to_one :firmware
  one_to_many :streams

  def config
    own = values[:config] || {}
    firmware.config.deep_merge(own)
  end

end

