Sequel.migration do

  up do
    alter_table(:users) do
      add_column :three_scale, :json
    end
  end

  down do
    alter_table(:users) do
      drop_column :three_scale
    end
  end

end