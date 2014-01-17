Sequel.migration do

  up do

    # cleanup old unused tables
    drop_table :_schema
    drop_table :streams_old
    drop_table :devices

    # update table names
    rename_table :streams, :cameras
    rename_table :access_tokens_streams_rights, :camera_rights

    # change to camera_rights
    alter_table :camera_rights do
      drop_column :stream_id
      drop_column :token_id

      add_foreign_key :camera_id, :cameras, null: false, on_delete: :cascade
      add_foreign_key :access_token_id, :access_tokens, on_delete: :cascade
      add_foreign_key :user_id, :users, on_delete: :cascade

      add_index [:camera_id, :access_token_id, :name], unique: true
      add_index [:camera_id, :user_id, :name], unique: true
    end

  end

end

