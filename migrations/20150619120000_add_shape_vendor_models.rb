Sequel.migration do

  up do
    alter_table(:vendor_models) do
      add_column :shape, String, null: true, default: ''
    end
  end

  down do
    alter_table(:vendor_models) do
      drop_column :shape
    end
  end

end