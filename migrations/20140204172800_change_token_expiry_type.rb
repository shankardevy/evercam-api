Sequel.migration do

  up do
    alter_table(:users) do
      drop_column :token_expires_at
      add_column :token_expires_at, :timestamp
    end
  end

end