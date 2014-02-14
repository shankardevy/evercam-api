class Firmware < Sequel::Model
  many_to_one :vendor
  one_to_many :cameras
  
  # Returns a deep merge of any config values set for this
  # firmware with the default vendor config 
  def config
    if '*' != name
      default = vendor.default_firmware ? vendor.default_firmware.config : {}
      default.deep_merge(values[:config])
    else 
      values[:config] || {}
    end
  end
  
end

