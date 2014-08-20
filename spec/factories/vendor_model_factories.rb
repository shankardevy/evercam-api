FactoryGirl.define do
  factory :vendor_model do
    association :vendor, factory: :vendor
    sequence(:name) { |n| "name#{n}" }
    sequence(:exid) { |n| "exid#{n}" }
    config({})
  end
end

