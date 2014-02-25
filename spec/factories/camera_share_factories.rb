FactoryGirl.define do
	factory :camera_share do
  	association :camera, factory: :camera
  	association :user, factory: :user
    association :sharer, factory: :user

    factory :public_camera_share do
    	kind 'public'
    end

    factory :private_camera_share do
    	kind 'private'
    end
	end
end

