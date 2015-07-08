Sequel.migration do
  up do
    create_table(:archives) do
      primary_key :id
      foreign_key :camera_id, :cameras, on_delete: :cascade, null: false
      foreign_key :requested_by, :users, on_delete: :cascade, null: false
      column :exid, :text, null: false
      column :title, :text, null: false
      column :from_date, :timestamptz, null: false
      column :to_date, :timestamptz, null: false
      column :status, :integer, null: false
      column :created_at, :timestamptz, null: false
      column :embed_time, :boolean, null: true
      column :public, :boolean, null: true
    end
  end

  down do
    drop_table(:archives)
  end
end