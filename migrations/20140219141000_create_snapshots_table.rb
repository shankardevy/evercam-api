Sequel.migration do

  up do

    create_table(:snapshots) do
      primary_key :id
      foreign_key :camera_id, :cameras, null: false
      column :created_at, :timestamptz, null: false
      column :notes, :text
      column :data, File, null: false
      index [:created_at, :camera_id], unique: true
    end

  end

  down do
    drop_table(:snapshots)
  end

end

