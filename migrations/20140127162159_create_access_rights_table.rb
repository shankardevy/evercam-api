Sequel.migration do

  up do

    create_table(:access_rights) do
      primary_key :id
      column :created_at, :timestamptz, null: false
      column :updated_at, :timestamptz, null: false
      foreign_key :token_id, :access_tokens, null: false
      column :name, :text, null: false
      index [:token_id, :name], unique: true
    end

    alter_table(:users) do
      drop_column :scopes
    end

    alter_table(:access_tokens) do
      drop_column :scopes
    end

  end

end

