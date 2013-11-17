class User < Sequel::Model

  include BCrypt

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

