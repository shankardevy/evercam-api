Sequel.migration do
  up do
    alter_table(:camera_share_requests) do
      add_column :message, Text
    end
  end

  down do
    alter_table(:camera_share_requests) do
      drop_column :message
    end
  end
end
