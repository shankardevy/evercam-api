module Evercam
  module Actors
    class CameraCreate < Mutations::Command

      required do
        string :id
        string :name

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

        if Camera.by_name(id)
          add_error(:camera, :exists, 'Camera already exists')
        end

        if nil == endpoints || endpoints.size == 0
          add_error(:endpoints, :size, 'Endpoints must contain at least one item')
        else
          endpoints.each do |e|
            unless e =~ URI.regexp
              add_error(:endpoints, :valid, 'One or more endpoints is not a valid URI')
            end
          end
        end
      end

      def execute
        camera = Camera.create({
          exid: id,
          name: name,
          owner: User.by_login(username),
          is_public: is_public,
          is_online: false,
          config: {
            snapshots: inputs[:snapshots],
            auth: inputs[:auth]
          }
        })

        inputs[:endpoints].each do |e|
          endpoint = URI.parse(e)
          camera.add_endpoint({
            scheme: endpoint.scheme,
            host: endpoint.host,
            port: endpoint.port
          })
        end

        camera
      end

    end
  end
end

