FactoryGirl.define do
  factory :stream do
    association :owner, factory: :user
    association :device, factory: :device
    sequence(:name) { |n| "stream#{n}" }
    snapshot_path '/Streaming/channels/1/picture'
  end
end

