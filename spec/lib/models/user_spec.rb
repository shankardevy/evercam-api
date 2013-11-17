require 'data_helper'

describe User do

  describe '#by_login' do

    let(:user) { create(:user) }

    it 'finds the user by username' do
      found = User.by_login(user.username)
      expect(found).to eq(user)
    end

    it 'finds the user by email' do
      found = User.by_login(user.email)
      expect(found).to eq(user)
    end

  end

  describe '#password' do

    it 'stores the password using bcrypt with cost 10' do
      user0 = User.new(password: 'garrett')
      hash0 = BCrypt::Password.new(user0.values[:password])
      expect(hash0.cost).to eq(10)
    end

    it 'returns a bcrypt password object for equality checking' do
      hash0 = BCrypt::Password.create('garrett')
      user0 = User.load(password: hash0.to_s)
      expect(user0.password).to eq('garrett')
    end

  end

end

