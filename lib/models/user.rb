class User < Sequel::Model

  include BCrypt

  one_to_many :streams, key: :owner_id
  one_to_many :tokens, class: 'AccessToken', key: :grantor_id
  many_to_one :country

  def self.by_login(val)
    where(username: val).or(email: val).first
  end

  def password
    Password.new(values[:password])
  end

  def password=(val)
    values[:password] = Password.create(val, cost: 10)
  end

end

