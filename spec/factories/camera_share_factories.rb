FactoryGirl.define do
	factory :camera_share do
     	association :user, factory: :user
      association :sharer, factory: :user

      factory :public_camera_share do
    	   kind 'public'
         association :camera, factory: :public_camera
      end

      factory :private_camera_share do
    	   kind 'private'
         association :camera, factory: :private_camera
      end
   end
end

