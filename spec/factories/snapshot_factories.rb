FactoryGirl.define do
  factory :snapshot do

    association :camera, factory: :camera
    sequence(:notes) { |n| "notes#{n}" }
    created_at Time.at(123456789)
    data File.read('spec/resources/snapshot.jpg')

  end
end

