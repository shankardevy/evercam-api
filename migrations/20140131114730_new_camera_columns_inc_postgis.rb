Sequel.migration do

  up do
    alter_table(:cameras) do
      rename_column :polled_at, :last_polled_at
      add_column :location, 'geography(POINT, 4326)'
      add_column :mac_address, :macaddr
    end
  end

end

