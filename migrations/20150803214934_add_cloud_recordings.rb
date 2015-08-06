Sequel.migration do
  up do
    create_table(:cloud_recordings) do
      primary_key :id
      foreign_key :camera_id, :cameras, null: false
      column :storage_duration, :integer, null: false
      column :schedule, :json
    end
  end

  down do
    drop_table(:cloud_recordings)
  end
end
