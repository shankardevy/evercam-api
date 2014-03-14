Sequel.migration do

  up do

    # update table names
    rename_table :firmwares, :vendor_models

    # change to cameras
    alter_table :cameras do
      add_foreign_key :model_id, :vendor_models
    end

    self.run("UPDATE cameras SET model_id=cameras.firmware_id WHERE firmware_id IS NOT NULL;");

    alter_table :cameras do
      drop_column :firmware_id
    end

  end

end
