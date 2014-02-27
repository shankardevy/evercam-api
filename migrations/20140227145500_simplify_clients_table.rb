Sequel.migration do

  up do
    alter_table(:clients) do
      set_column_allow_null(:callback_uris)
      set_column_allow_null(:secret)
      set_column_allow_null(:name)
    end
  end

  down do
    alter_table(:clients) do
      set_column_not_null(:name)
      set_column_not_null(:secret)
      set_column_not_null(:callback_uris)
    end
  end

end

