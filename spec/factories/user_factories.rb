FactoryGirl.define do
  factory :user do
    sequence(:forename) { |n| "forename#{n}" }
    sequence(:lastname) { |n| "lastname#{n}" }
    sequence(:username) { |n| "username#{n}" }
    sequence(:password) { |n| "password#{n}" }
    sequence(:email) { |n| "email#{n}evercam.io" }
    country_id 100
  end
end

