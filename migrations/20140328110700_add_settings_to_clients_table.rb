Sequel.migration do

  up do
  	alter_table(:clients) do
  		add_column :settings, :text, null: true
  	end
  end

  down do
    alter_table(:clients) do
      drop_column :settings
    end
  end

end