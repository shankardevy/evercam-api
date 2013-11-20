FactoryGirl.define do
  factory :access_token do
    association :grantor, factory: :user
    association :grantee, factory: :client
  end
end

