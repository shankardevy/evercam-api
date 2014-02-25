Sequel.migration do

  up do

    create_table(:camera_shares) do
      primary_key :id
      foreign_key :camera_id, :cameras, on_delete: :cascade, null: false
      foreign_key :user_id, :users, on_delete: :cascade, null: false
      foreign_key :sharer_id, :users, on_delete: :set_null
      String :kind, null: false, size: 50
      column :created_at, :timestamptz, null: false
      column :updated_at, :timestamptz, null: false
      index [:camera_id, :user_id], unique: true
      index [:camera_id]
      index [:user_id]
    end

  end

  down do
    drop_table(:camera_shares)
  end

end

