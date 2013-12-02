class DeviceVendor < Sequel::Model

  one_to_many :devices, key: :vendor_id

  def prefixes=(val)
    val = Sequel.pg_array(
      val.map(&:upcase).uniq) if val
    values[:prefixes] = val
  end

  def self.by_prefix(val)
    first(%("prefixes" @> ARRAY[?]), val.upcase)
  end

end

