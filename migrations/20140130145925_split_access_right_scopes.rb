Sequel.migration do

  up do
    alter_table(:access_rights) do
      drop_column :name
      add_column :group, :text, null: false
      add_column :right, :text, null: false
      add_column :scope, :text, null: false
      add_index [:token_id, :group, :right, :scope], unique: true
    end
  end

end

