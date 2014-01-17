class AccessRight < Sequel::Model
  many_to_one :token, class: 'AccessToken', key: :access_token_id
end

class CameraRight < AccessRight
  set_dataset db[:camera_rights]
  many_to_one :camera
end

