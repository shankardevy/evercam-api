FactoryGirl.define do
  factory :camera do

    association :owner, factory: :user
    sequence(:name) { |n| "stream#{n}" }
    is_public true

    config({
      endpoints: ['http://127.0.0.1'],
      snapshots: {
        jpg: '/onvif/snapshot'
      },
      auth: {
        basic: {
          username: 'abcd',
          password: 'wxyz'
        }
      }
    })

  end
end

