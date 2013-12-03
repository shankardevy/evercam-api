class Device < Sequel::Model

  many_to_one :firmware
  one_to_many :streams

  def config
    firmware.config.merge(values[:config])
  end

end

