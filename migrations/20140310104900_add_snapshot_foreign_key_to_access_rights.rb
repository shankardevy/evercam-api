Sequel.migration do

  up do
    alter_table(:access_rights) do
      add_foreign_key :snapshot_id, :snapshots, null: true, on_delete: :cascade
    end
  end

  down do
    alter_table(:access_rights) do
      drop_constraint "access_rights_snapshot_id_fkey"
      drop_column :snapshot_id
    end
  end

end