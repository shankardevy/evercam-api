Sequel.migration do
   up do
      create_table(:camera_share_requests) do
         primary_key :id
         foreign_key :camera_id, :cameras, on_delete: :cascade, null: false
         foreign_key :user_id, :users, on_delete: :cascade, null: false
         String :key, null: false, size: 100
         String :email, null: false, size: 250
         Integer :status, null: false
         String :rights, null: false, size: 1000
         column :created_at, :timestamptz, null: false
         column :updated_at, :timestamptz, null: false
         index [:camera_id, :email], unique: true
         index [:key], unique: true
      end
   end

   down do
      drop_table(:camera_share_requests)
   end
end
