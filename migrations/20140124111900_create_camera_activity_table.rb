Sequel.migration do

  up do

    create_table(:camera_activities) do

      primary_key :id
      foreign_key :camera_id, :cameras, on_delete: :cascade, null: false
      foreign_key :access_token_id, :access_tokens, on_delete: :cascade
      column :action, :text, null: false
      column :done_at, :timestamptz, null: false
      column :ip, :inet

      index [:camera_id, :access_token_id, :done_at], unique: true

    end

  end

end
