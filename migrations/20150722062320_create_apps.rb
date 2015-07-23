Sequel.migration do
  up do
    create_table(:apps) do
      primary_key :id
      foreign_key :camera_id, :cameras, on_delete: :cascade, null: false
      column :local_recording, :boolean, null: false, default: false
      column :cloud_recording, :boolean, null: false, default: false
      column :motion_detection, :boolean, null: false, default: false
      column :watermark, :boolean, null: false, default: false
    end
  end

  down do
    drop_table(:apps)
  end
end
