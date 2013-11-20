FactoryGirl.define do
  factory :access_token_stream_right do
    association :token, factory: :access_token
    association :stream, factory: :stream
    name 'abcd'
  end
end

