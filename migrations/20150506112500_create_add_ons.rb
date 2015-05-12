Sequel.migration do
  up do
    create_table(:add_ons) do
      primary_key :id
      foreign_key :user_id, :users, on_delete: :cascade, null: false
      column :add_ons_name, :text, null: false
      column :period, :text, null: false
      column :add_ons_start_date, :timestamptz, null: false
      column :add_ons_end_date, :timestamptz, null: false
      column :status, :boolean, null: false
      column :price, :double, null: false
      column :created_at, :timestamptz, null: false
      column :updated_at, :timestamptz, null: false
    end
  end

  down do
    drop_table(:add_ons)
  end
end