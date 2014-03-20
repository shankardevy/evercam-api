FactoryGirl.define do
  factory :client do
    sequence(:name) { |n| "client#{n}" }
    callback_uris ['http://127.0.0.1']
    sequence(:exid) {|n| SecureRandom.hex(10)}
    sequence(:secret) {|n| SecureRandom.hex(16)}
  end
end

