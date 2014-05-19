Sequel.migration do
  up do
   alter_table(:camera_share_requests) do
      drop_index [:camera_id, :email]
      add_index [:camera_id, :email], unique: false
   end
  end

  down do
   alter_table(:camera_share_requests) do
      drop_index [:camera_id, :email]
      add_index [:camera_id, :email], unique: true
   end
  end
end