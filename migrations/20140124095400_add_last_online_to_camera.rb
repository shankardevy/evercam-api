Sequel.migration do

  up do

    alter_table(:cameras) do
      add_column :last_online_at, :timestamptz
    end

  end

end

