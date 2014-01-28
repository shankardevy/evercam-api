FactoryGirl.define do
  factory :access_right do
    association :token, factory: :access_token
    sequence(:name) { |n| "name#{n}" }
  end
end

