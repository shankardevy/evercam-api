Sequel.migration do
  up do
    alter_table :clients do
      rename_column :secret, :api_key
      rename_column :exid, :api_id
    end
  end

  down do
    alter_table :clients do
      rename_column :api_id, :exid
      rename_column :api_key, :secret
    end
  end
end
