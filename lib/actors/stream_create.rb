module Evercam
  module Actors
    class StreamCreate < Mutations::Command

      required do
        string :id
        string :username
        array :endpoints, class: String, min: 1
        boolean :is_public

        hash :snapshots do
          string :jpg
        end

        hash :auth do
          hash :basic do
            string :username
            string :password
          end
        end
      end

      def validate
        unless User.by_login(username)
          add_error(:username, :exists, 'Username does not exist')
        end

        if Stream.by_name(id)
          add_error(:stream, :exists, 'Stream already exists')
        end

        unless endpoints.size > 0
          add_error(:endpoints, :size, 'Endpoints must contain at least one item')
        end
      end

      def execute
        User.db.transaction do
          owner = User.by_login(username)

          device = Device.create({
            external_uri: endpoints[0],
            internal_uri: endpoints[0],
            config: config
          })

          Stream.create({
            name: id,
            owner: owner,
            device: device,
            snapshot_path: snapshots[:jpg],
            is_public: is_public
          })
        end
      end

      def config
        {}.merge(auth: inputs[:auth])
      end

    end
  end
end

