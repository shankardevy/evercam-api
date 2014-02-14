class Vendor < Sequel::Model

  REGEX_MAC = /([0-9A-F]{2}[:-]){2,5}([0-9A-F]{2})/i

  one_to_many :firmwares

  dataset_module do

    def by_exid(val)
      where(exid: val)
    end

    def by_mac(val)
      where(%("known_macs" @> ARRAY[?]), val.upcase[0,8])
    end

    def supported
      join(:firmwares, :vendor_id => :id).distinct(:id).
        select_all(:vendors)
    end

  end

  def known_macs=(val)
    val = Sequel.pg_array(
      val.map(&:upcase).uniq) if val
    values[:known_macs] = val
  end

  def get_firmware_for(val)
    match_firmware(val) || default_firmware
  end

  def default_firmware
    firmwares.find do |f|
      '*' == f.name 
    end
  end

  private

  def match_firmware(val)
    firmwares.find do |f|
      '*' != f.name && nil != val.upcase.match(f.name.upcase)
    end
  end

end

