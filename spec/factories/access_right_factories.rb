FactoryGirl.define do
  factory :access_right do
    association :token, factory: :access_token
    association :camera, factory: :camera
    status AccessRight::ACTIVE
    right  AccessRight::SNAPSHOT
  end
end

