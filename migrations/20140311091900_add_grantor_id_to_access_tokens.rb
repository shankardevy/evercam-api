Sequel.migration do

  up do
  	alter_table(:access_tokens) do
      add_foreign_key :grantor_id, :users, null: true, on_delete: :cascade
  	end
  end

  down do
    alter_table(:access_tokens) do
      drop_constraint :access_tokens_grantor_id_fkey
      drop_column :grantor_id
    end
  end

end