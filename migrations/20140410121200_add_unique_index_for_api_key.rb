Sequel.migration do

  up do
    alter_table(:users) do
      add_index [:api_id], unique: true
    end
  end

end

