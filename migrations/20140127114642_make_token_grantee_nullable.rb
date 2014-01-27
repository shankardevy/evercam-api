Sequel.migration do

  up do
    alter_table(:access_tokens) do
      set_column_allow_null :grantee_id
    end
  end

end

