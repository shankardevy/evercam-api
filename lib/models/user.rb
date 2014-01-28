require 'bcrypt'

class User < Sequel::Model

  include BCrypt

  many_to_one :country
  one_to_many :cameras, key: :owner_id

  one_to_many :grants, class: 'AccessToken',
    conditions: Sequel.negate(grantee_id: nil),
    key: :grantor_id

  one_to_one :token, class: 'AccessToken',
    conditions: { grantee_id: nil },
    after_load: proc { |u| u.send(:ensure_token_exists) },
    key: :grantor_id

  def self.by_login(val)
    where(username: val).or(email: val).first
  end

  def fullname
    [forename, lastname].join(' ')
  end

  def password
    Password.new(values[:password])
  end

  def password=(val)
    values[:password] = Password.create(val, cost: 10)
  end

  def confirmed?
    false == self.confirmed_at.nil?
  end

  private

  def ensure_token_exists
    self.token ||= AccessToken.new(
      expires_at: Time.at(2**31))
  end

end

