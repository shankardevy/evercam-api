FactoryGirl.define do
  factory :stream do
    association :owner, factory: :user
    association :device, factory: :device
    sequence(:name) { |n| "stream#{n}" }
  end
end

