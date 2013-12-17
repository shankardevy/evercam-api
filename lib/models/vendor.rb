class Vendor < Sequel::Model

  REGEX_MAC = /([0-9A-F]{2}[:-]){2,5}([0-9A-F]{2})/i

  one_to_many :firmwares

  def self.by_mac(val)
    where(%("known_macs" @> ARRAY[?]), val.upcase)
  end

  def self.by_exid(val)
    where(exid: val)
  end

  def known_macs=(val)
    val = Sequel.pg_array(
      val.map(&:upcase).uniq) if val
    values[:known_macs] = val
  end

  def get_firmware_for(val)
    match_firmware(val) || default_firmware
  end

  private

  def match_firmware(val)
    firmwares.find do |f|
      f.known_models.any? do |m|
        '*' != m && nil != val.upcase.match(m.upcase)
      end
    end
  end

  def default_firmware
    firmwares.find do |f|
      f.known_models.include?('*')
    end
  end

end

