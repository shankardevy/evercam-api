Sequel.migration do
  up do
   alter_table(:access_rights) do
      drop_index [:token_id, :camera_id, :right]
   end
  end

  down do
   alter_table(:access_rights) do
      add_index [:token_id, :camera_id, :right], unique: true
   end
  end
end

