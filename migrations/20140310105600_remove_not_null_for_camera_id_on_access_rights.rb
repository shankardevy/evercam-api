Sequel.migration do

  up do
    alter_table(:access_rights) do
      set_column_allow_null :camera_id
    end
  end

  down do
    alter_table(:access_rights) do
      set_column_not_null :camera_id
    end
  end

end