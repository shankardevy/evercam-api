class Vendor < Sequel::Model

  REGEX_MAC = /([0-9A-F]{2}[:-]){2,5}([0-9A-F]{2})/i

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

