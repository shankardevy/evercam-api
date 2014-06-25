Sequel.migration do

  up do

    alter_table :users do
      rename_column :forename, :firstname
    end

  end

  down do

    alter_table :users do
      rename_column :firstname, :forename
    end

  end

end
