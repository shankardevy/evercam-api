module Evercam
  module Actors
    class StreamCreate < Mutations::Command

      required do
        string :id
        string :username
        array :endpoints, class: String
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

        unless endpoints && endpoints.size > 0
          add_error(:endpoints, :size, 'Endpoints must contain at least one item')
        end
      end

      def execute
        Stream.create({
          name: id,
          owner: User.by_login(username),
          is_public: is_public,
          config: {
            endpoints: inputs[:endpoints],
            snapshots: inputs[:snapshots],
            auth: inputs[:auth]
          }
        })
      end

    end
  end
end

