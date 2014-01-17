Sequel.migration do

  up do

    alter_table(:cameras) do
      rename_column :name, :exid
      add_column :name, :text
      add_column :is_online, :boolean
    end

    from(:cameras).update({
      name: 'My Camera',
      is_online: false
    })

    alter_table(:cameras) do
      set_column_not_null :name
      set_column_not_null :is_online
    end

  end

end

