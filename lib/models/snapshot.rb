class Snapshot < Sequel::Model
  many_to_one :camera

  # Convenience mechanism for fetching the user who owns a snapshot.
  def owner
  	 self.camera.owner
  end
end
