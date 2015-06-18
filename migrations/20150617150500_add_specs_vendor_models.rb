Sequel.migration do

  up do
    alter_table(:vendor_models) do
      add_column :specs, :json, null: true
    end
  end

  down do
    alter_table(:vendor_models) do
      drop_column :specs
    end
  end

end