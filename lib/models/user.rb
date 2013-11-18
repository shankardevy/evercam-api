class User < Sequel::Model

  include BCrypt

  one_to_many :streams, key: :owner_id

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

