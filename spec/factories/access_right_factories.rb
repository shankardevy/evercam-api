FactoryGirl.define do
  factory :access_right do
    association :token, factory: :access_token
    status AccessRight::ACTIVE

    factory :camera_access_right do
      association :camera, factory: :camera
      snapshot nil
      snapshot_id nil
      account nil
      account_id nil
      scope nil
      right AccessRight::SNAPSHOT
    end

    factory :snapshot_access_right do
      association :snapshot, factory: :snapshot
      camera nil
      camera_id nil
      account nil
      account_id nil
      scope nil
      right AccessRight::VIEW
    end

    factory :account_access_right do
      association :account, factory: :user
      camera nil
      camera_id nil
      snapshot nil
      snapshot_id nil
      scope AccessRight::SNAPSHOTS
      right AccessRight::VIEW
    end
  end
end

