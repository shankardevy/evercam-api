FactoryGirl.define do
  factory :vendor_model do
    association :vendor, factory: :vendor
    sequence(:name) { |n| "name#{n}" }
    known_models ['*']
    config({})
  end
end

