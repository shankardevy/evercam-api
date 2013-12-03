class Vendor < Sequel::Model

  one_to_many :firmwares

  def known_macs=(val)
    val = Sequel.pg_array(
      val.map(&:upcase).uniq) if val
    values[:known_macs] = val
  end

  def self.by_mac(val)
    where(%("known_macs" @> ARRAY[?]), val.upcase).all
  end

  def self.by_exid(val)
    first(exid: val)
  end

end

