FactoryGirl.define do
  factory :device do
    association :vendor, factory: :device_vendor
    external_uri 'http://93.184.216.119'
    internal_uri 'http://192.168.1.100'
    username 'qwertyuiop'
    password 'asdfghjkl'
  end
end

