class Snapshot < Sequel::Model
  many_to_one :camera

  def self.by_ts(timestamp)
    first(created_at: timestamp.to_s)
  end

  def self.by_ts!(timestamp)
    by_ts(timestamp)  || (
    raise Evercam::NotFoundError, 'Snapshot does not exist')
  end

end

