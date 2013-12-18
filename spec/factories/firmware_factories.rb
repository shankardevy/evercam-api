FactoryGirl.define do
  factory :firmware do
    vendor
    sequence(:name) { |n| "name#{n}" }
    known_models ['*']
    config({})
  end
end

