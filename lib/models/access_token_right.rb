class AccessTokenRight < Sequel::Model
  many_to_one :token, class: 'AccessToken'
end

class AccessTokenStreamRight < AccessTokenRight
  set_dataset db[:access_tokens_streams_rights]
  many_to_one :stream
end

