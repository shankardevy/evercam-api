require 'data_helper'

describe User do

  describe '#by_login' do

    let(:user) { create(:user) }

    it 'finds a user by username' do
      assert_equal user, User.by_login(user.username)
    end

    it 'finds a user by email' do
      assert_equal user, User.by_login(user.email)
    end

  end

  describe '#password' do

    it 'stores the password using bcrypt with cost 10' do
      user0 = User.new(password: 'garrett')
      hash0 = BCrypt::Password.new(user0.values[:password])
      assert_equal 10, hash0.cost
    end

    it 'returns a bcrypt password object for equality checking' do
      hash0 = BCrypt::Password.create('garrett')
      user0 = User.load(password: hash0.to_s)
      assert_equal user0.password, 'garrett'
    end

  end

end

