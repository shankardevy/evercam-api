Sequel.migration do

  up do

    alter_table(:cameras) do
      rename_column :name, :exid
      add_column :name, :text
      add_column :is_online, :boolean
      add_column :last_heartbeat_at, :timestamptz
    end

    from(:cameras).update({
      name: 'My Camera'
    })

    alter_table(:cameras) do
      set_column_not_null :name
    end

  end

end

