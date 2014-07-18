FactoryGirl.define do
  factory :camera_share_request do
    association :camera, factory: :camera
    association :user, factory: :user
    key {SecureRandom.hex(25)}
    sequence(:email) {|n| "unknown.user.#{n}@nowhere.com"}
    status CameraShareRequest::PENDING
    rights "list,view"

    factory :pending_camera_share_request do
       status CameraShareRequest::PENDING
    end

    factory :used_camera_share_request do
       status CameraShareRequest::USED
    end

    factory :cancelled_camera_share_request do
       status CameraShareRequest::CANCELLED
    end
  end
end

