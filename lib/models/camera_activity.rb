class CameraActivity < Sequel::Model

  many_to_one :camera
  many_to_one :user

  def to_s
    "[#{camera.name}] #{user.fullname} #{action} #{done_at}"
  end

end

