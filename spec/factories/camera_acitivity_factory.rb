FactoryGirl.define do
  factory :camera_activity do

    association :camera, factory: :camera
    association :access_token, factory: :access_token

    action 'Test'
    ip '1.1.1.1'
    done_at Time.now - 1.minute

  end

end

