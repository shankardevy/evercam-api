class Stream < Sequel::Model

  many_to_one :device
  one_to_many :permissions, class: 'AccessTokenStreamRight'
  many_to_one :owner, class: 'User'

  def self.by_name(name)
    first(name: name)
  end

  def has_right?(name, seeker)
    case seeker
    when User
      seeker == self.owner
    when AccessToken
      nil != permissions_dataset.
        first(token: seeker, name: name)
    end
  end

end

