class CameraActivity < Sequel::Model

  many_to_one :camera, class: 'Camera'
  many_to_one :access_token, class: 'AccessToken'

  def to_s
    if access_token.nil?
      "[#{camera.name}] Anonymous #{action} at #{done_at} from #{ip}"
    else
      "[#{camera.name}] #{access_token.grantor.fullname} #{action} at #{done_at} from #{ip}"
    end
  end

end

