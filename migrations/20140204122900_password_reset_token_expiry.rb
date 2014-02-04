Sequel.migration do

  up do
    alter_table(:users) do      
      add_column :reset_token, :text
      add_column :token_expires_at, :timestamptz
    end
  end

end