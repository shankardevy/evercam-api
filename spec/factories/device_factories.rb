FactoryGirl.define do
  factory :device do

    firmware

    external_uri 'http://93.184.216.119'
    internal_uri 'http://192.168.1.100'

    config({
      auth:{
        basic: {
          username: 'qwertyuiop',
          password: 'asdfghjkl'
        }
      }
    })

  end
end

