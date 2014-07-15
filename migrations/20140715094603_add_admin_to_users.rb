Sequel.migration do

  up do
    alter_table(:users) do
      add_column :is_admin, :boolean, null: false, default: false
    end
  end

  down do
    alter_table(:users) do
      drop_column :is_admin
    end
  end

end
