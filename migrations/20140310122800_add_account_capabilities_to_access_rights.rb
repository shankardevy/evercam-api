Sequel.migration do

  up do
    alter_table(:access_rights) do
      add_foreign_key :account_id, :users, null: true, on_delete: :cascade
      add_column :scope, String, null: true, size: 100
    end
  end

  down do
    alter_table(:access_rights) do
      drop_constraint "access_rights_account_id_fkey"
      drop_column :account_id
      drop_column :scope
    end
  end

end