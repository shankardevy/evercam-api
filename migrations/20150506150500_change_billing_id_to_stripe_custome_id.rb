Sequel.migration do
  up do
    alter_table :users do
      rename_column :billing_id, :stripe_customer_id
    end
  end

  down do
    alter_table :users do
      rename_column :stripe_customer_id, :billing_id
    end
  end

end