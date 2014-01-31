FactoryGirl.define do
  factory :access_right do
    association :token, factory: :access_token
    sequence(:group) { |n| "group#{n}" }
    sequence(:right) { |n| "right#{n}" }
    sequence(:scope) { |n| "scope#{n}" }
  end
end

