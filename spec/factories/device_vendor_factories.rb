FactoryGirl.define do
  factory :device_vendor do
    sequence(:name) { |n| "vendor#{n}" }
    prefixes ['00:00:01']
  end
end

