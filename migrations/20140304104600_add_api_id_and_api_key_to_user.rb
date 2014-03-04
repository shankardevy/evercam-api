Sequel.migration do

  up do
    alter_table(:users) do
      add_column :api_id, :text
      add_column :api_key, :text
    end
  end

  down do
    alter_table(:users) do
      drop_column :api_id
      drop_column :api_key
    end
  end

end