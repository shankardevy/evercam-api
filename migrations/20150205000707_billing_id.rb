Sequel.migration do
  up do
    alter_table(:users) do
      add_column :stripe_customer_id, :text
    end
  end

  down do
    alter_table(:users) do
      drop_column :stripe_customer_id
    end
  end
end
