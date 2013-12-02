FactoryGirl.define do
  factory :vendor do
    sequence(:exid) { |n| "exid#{n}" }
    known_macs ['00:00:01', '00:00:0A']
    sequence(:name) { |n| "name#{n}" }
  end
end

