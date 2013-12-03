FactoryGirl.define do
  factory :firmware do
    vendor
    sequence(:name) { |n| "name#{n}" }
    config({a: 1})
  end
end

