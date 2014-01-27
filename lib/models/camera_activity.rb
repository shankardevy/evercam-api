class CameraActivity < Sequel::Model

  many_to_one :camera, class: 'Camera'
  many_to_one :access_token, class: 'AccessToken'

  def to_s
    if access_token.nil?
      "[#{camera.name}] Anonymous #{action} #{done_at}"
    else
      "[#{camera.name}] #{access_token.grantor.fullname} #{action} #{done_at}"
    end
  end

end

