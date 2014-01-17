FactoryGirl.define do
  factory :camera_right do
    association :camera, factory: :camera
    association :token, factory: :access_token
    name 'abcd'
  end
end

