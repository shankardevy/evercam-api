Sequel.migration do
  up do
    alter_table(:cameras) do
      add_column :discoverable, :boolean, null: false, default: false
    end
    self[:cameras].all.each do |record|
      if record[:config]
        configuration = record[:config]
        if configuration.include?("discoverable")
          copy = {}.merge(configuration)
          copy.delete("discoverable")
          self[:cameras].where(id: record[:id]).update(discoverable: (configuration["discoverable"] == true),
                                                       config: copy.to_json)
        end
      end
    end
  end

  down do
    self[:cameras].all.each do |record|
      configuration = record[:config] || {}
      configuration["discoverable"] = record[:discoverable]
      self[:cameras].where(id: record[:id]).update(config: configuration.to_json)
    end
    alter_table(:cameras) do
      drop_column :discoverable
    end
  end
end

