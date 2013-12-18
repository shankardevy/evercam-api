class Device < Sequel::Model

  many_to_one :firmware
  one_to_many :streams

  def config
    fconf = firmware ? firmware.config : {}
    fconf.deep_merge(values[:config] || {})
  end

end

