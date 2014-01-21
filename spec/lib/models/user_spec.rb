require 'data_helper'

describe User do

  describe '#by_login' do

    let(:user) { create(:user) }

    context 'when given a username' do
      it 'finds the user' do
        found = User.by_login(user.username)
        expect(found).to eq(user)
      end
    end

    context 'when given an email' do
      it 'finds the user' do
        found = User.by_login(user.email)
        expect(found).to eq(user)
      end
    end

  end

  describe '#password' do

    context 'when setting a new value' do
      it 'stores it using bcrypt cost 10' do
        user0 = User.new(password: 'garrett')
        hash0 = BCrypt::Password.new(user0.values[:password])
        expect(hash0.cost).to eq(10)
      end
    end

    context 'when reading an existing value' do
      it 'returns a bcrypt password checking object' do
        hash0 = BCrypt::Password.create('garrett')
        user0 = User.load(password: hash0.to_s)
        expect(user0.password).to eq('garrett')
      end
    end

  end

  describe '#scopes' do

    context 'when the database is null' do
      it 'returns an empty set' do
        user0 = User.new(scopes: nil)
        expect(user0.scopes).to be_empty
      end
    end

  end

end

