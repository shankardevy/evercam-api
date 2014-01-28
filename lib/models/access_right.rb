class AccessRight < Sequel::Model

  many_to_one :token, class: 'AccessToken'

end

