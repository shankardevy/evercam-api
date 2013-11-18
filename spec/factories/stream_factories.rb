FactoryGirl.define do
  factory :stream do
    sequence(:name) { |n| "stream#{n}" }
    association :device, factory: :device
    association :owner, factory: :user
    snapshot_path '/Streaming/channels/1/picture'
    is_public true
  end
end

