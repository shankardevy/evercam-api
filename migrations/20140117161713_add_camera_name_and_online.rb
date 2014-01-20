Sequel.migration do

  up do

    alter_table(:cameras) do
      rename_column :name, :exid
      add_column :name, :text
      add_column :polled_at, :timestamptz
      add_column :is_online, :boolean
    end

    from(:cameras).update({
      name: 'My Camera'
    })

    alter_table(:cameras) do
      set_column_not_null :name
    end

  end

end

