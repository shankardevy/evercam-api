class Vendor < Sequel::Model

  one_to_many :devices

  def known_macs=(val)
    val = Sequel.pg_array(
      val.map(&:upcase).uniq) if val
    values[:known_macs] = val
  end

  def self.by_mac(val)
    where(%("known_macs" @> ARRAY[?]), val.upcase).all
  end

end

