require_relative '../workers'

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

      optional do
        string :timezone
      end

      def validate
        unless User.by_login(username)
          add_error(:username, :exists, 'Username does not exist')
        end

        if Camera.by_exid(id)
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

        if timezone && false == Timezone::Zone.names.include?(timezone)
          add_error(:timezone, :valid, 'Timezone does not exist or is invalid')
        end
      end

      def execute
        camera = Camera.new({
          exid: id,
          name: name,
          owner: User.by_login(username),
          is_public: is_public,
          config: {
            snapshots: inputs[:snapshots],
            auth: inputs[:auth]
          }
        })

        camera.timezone = timezone if timezone
        camera.save

        inputs[:endpoints].each do |e|
          endpoint = URI.parse(e)

          camera.add_endpoint({
            scheme: endpoint.scheme,
            host: endpoint.host,
            port: endpoint.port
          })

          DNSUpsertWorker.perform_async(id, endpoint.host)
        end

        camera
      end

    end
  end
end

