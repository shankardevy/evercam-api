FactoryGirl.define do
  factory :camera do

    association :owner, factory: :user
    sequence(:name) { |n| "stream#{n}" }
    is_public true

    config({
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

