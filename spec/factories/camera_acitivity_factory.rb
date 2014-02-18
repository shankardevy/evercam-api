FactoryGirl.define do
  factory :camera_activity do

    association :camera, factory: :camera
    association :user, factory: :user

    action 'Test'
    done_at Time.now

  end

end

