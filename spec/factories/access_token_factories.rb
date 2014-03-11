FactoryGirl.define do
  factory :access_token do
    association :user, factory: :user
    association :client, factory: :client
    association :grantor, factory: :user
  end
end

