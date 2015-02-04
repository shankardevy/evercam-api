Sequel.migration do
  up do
    alter_table(:users) do
      add_column :billing_id, :text
    end
  end

  down do
    alter_table(:users) do
      drop_column :billing_id
    end
  end
end
