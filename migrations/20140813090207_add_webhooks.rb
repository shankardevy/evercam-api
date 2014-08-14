Sequel.migration do

  up do

    create_table(:webhooks) do
      primary_key :id
      foreign_key :camera_id, :cameras, on_delete: :cascade, null: false
      foreign_key :user_id, :users, on_delete: :cascade, null: false
      String :url, null: false
      column :created_at, :timestamptz, null: false
      column :updated_at, :timestamptz, null: false
    end

  end

  down do
    drop_table(:webhooks)
  end

end

