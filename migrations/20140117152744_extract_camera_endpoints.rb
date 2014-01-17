Sequel.migration do

  up do

    # create new endpoints table
    create_table(:camera_endpoints) do

      primary_key :id
      foreign_key :camera_id, :cameras, on_delete: :cascade
      column :scheme, :text, null: false
      column :host, :text, null: false
      column :port, :integer, null: false

      index [:camera_id, :scheme, :host, :port], unique: true

    end

    # convert each cameras endpoints to a record
    from(:cameras).each do |c|

      config = c[:config]

      # create new entry in endpoints table
      config['endpoints'].each do |e|

        endpoint = URI.parse(e)

        values = {
          camera_id: c[:id],
          scheme: endpoint.scheme || 'http',
          host: endpoint.host || e,
          port: endpoint.port || 80
        }

        unless 0 < from(:camera_endpoints).where(values).count
          from(:camera_endpoints).insert(values)
        end

      end

      # remove endpoints from config json
      config.delete('endpoints')

      from(:cameras).where(id: c[:id]).
        update(config: config)

    end

  end

end

