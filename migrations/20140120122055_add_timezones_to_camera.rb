Sequel.migration do

  up do

    # add zone link from cameras
    alter_table(:cameras) do
      add_column :timezone, :text
    end

  end

end

