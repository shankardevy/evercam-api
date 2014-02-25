Sequel.migration do

  up do
  	alter_table(:access_tokens) do
  		rename_column :grantor_id, :user_id
  		rename_column :grantee_id, :client_id
      set_column_allow_null :user_id
  	end
  end

  down do
  	alter_table(:access_tokens) do
      set_column_not_null :user_id
  		rename_column :user_id, :grantor_id
  		rename_column :client_id, :grantee_id
  	end
  end

end