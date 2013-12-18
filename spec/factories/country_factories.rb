FactoryGirl.define do
  factory :country do
    sequence(:iso3166_a2)
    sequence(:name) { |n| "country#{n}" }
  end
end

