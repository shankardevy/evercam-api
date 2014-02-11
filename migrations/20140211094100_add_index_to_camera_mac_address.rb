Sequel.migration do

  up do
  	 add_index(:cameras, [:mac_address], unique: true)
  end

  down do
  	 drop_index(:cameras, [:mac_address])
  end

end