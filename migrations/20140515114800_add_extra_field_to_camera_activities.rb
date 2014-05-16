Sequel.migration do

  up do
    alter_table(:camera_activities) do
      add_column :extra, :json, null: true
    end
  end

  down do
    alter_table(:camera_activities) do
      drop_column :extra
    end
  end

end