FactoryGirl.define do
  factory :client do
    sequence(:name) { |n| "client#{n}" }
    callback_uris ['http://127.0.0.1']
  end
end

