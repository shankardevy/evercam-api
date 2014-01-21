Sequel.migration do

  up do

    drop_table :camera_rights

    alter_table(:users) do
      add_column :scopes, 'text[]'
    end

    alter_table(:access_tokens) do
      add_column :scopes, 'text[]'
    end

  end

end

