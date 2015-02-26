Sequel.migration do

  up do
    alter_table(:cameras) do
      add_column :thumbnail_url, String
    end
  end

  down do
    alter_table(:cameras) do
      drop_column :thumbnail_url
    end
  end

end
