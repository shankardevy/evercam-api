class Snapshot < Sequel::Model
  many_to_one :camera

  DEFAULT_RANGE = 1

  def self.by_ts(timestamp, range=nil)
    range ||= DEFAULT_RANGE
    if range < DEFAULT_RANGE then range = DEFAULT_RANGE end
    order(:created_at).last(:created_at => (timestamp - range + 1).to_s...(timestamp + range).to_s)
  end

  def self.by_ts!(timestamp, range=nil)
    by_ts(timestamp, range)  || (
    raise Evercam::NotFoundError, 'Snapshot does not exist')
  end

end
