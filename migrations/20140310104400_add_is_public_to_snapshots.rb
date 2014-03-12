Sequel.migration do

  up do
    alter_table(:snapshots) do
      add_column :is_public, :boolean, null: false, default: false
    end
  end

  down do
    alter_table(:snapshots) do
      drop_column :is_public
    end
  end

end