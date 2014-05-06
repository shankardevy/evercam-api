Sequel.migration do
  up do
   alter_table(:access_rights) do
      drop_index [:token_id, :camera_id, :right]
      add_index [:token_id, :camera_id, :right], unique: false
   end
  end

  down do
   alter_table(:access_rights) do
      drop_index [:token_id, :camera_id, :right]
      add_index [:token_id, :camera_id, :right], unique: true
   end
  end
end

