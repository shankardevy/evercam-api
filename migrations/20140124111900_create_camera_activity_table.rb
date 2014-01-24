Sequel.migration do

  up do

    create_table(:camera_activities) do

      primary_key :id
      foreign_key :camera_id, :cameras, on_delete: :cascade
      foreign_key :user_id, :users, on_delete: :cascade
      column :action, :text, null: false
      column :done_at, :timestamptz, null: false

      index [:camera_id, :user_id, :done_at], unique: true

    end

  end

end
