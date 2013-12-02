class Device < Sequel::Model
  one_to_many :streams
  many_to_one :vendor, class: 'DeviceVendor'
end

