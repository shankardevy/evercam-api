Sequel.migration do
  up do
    alter_table(:camera_shares) do
      add_column :message, :text
    end
  end

  down do
    alter_table(:camera_shares) do
      drop_column :message
    end
  end
end
