Sequel.migration do
  up do
   alter_table(:camera_shares) do
      drop_index [:camera_id, :user_id]
      add_index [:camera_id, :user_id], unique: false
   end
  end

  down do
   alter_table(:camera_shares) do
      drop_index [:camera_id, :user_id]
      add_index [:camera_id, :user_id], unique: true
   end
  end
end

