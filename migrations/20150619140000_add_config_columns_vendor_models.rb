Sequel.migration do
  up do
    alter_table(:vendor_models) do
      add_column :username, :text, null: true
      add_column :password, :text, null: true
    end
  end

  down do
    alter_table(:vendor_models) do
      drop_column :username
      drop_column :password
    end
  end
end
