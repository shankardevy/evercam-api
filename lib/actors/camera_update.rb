require_relative '../workers'

module Evercam
  module Actors
    class CameraUpdate < Mutations::Command

      required do
        string :id
      end

      optional do
        string :timezone
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
        if username && nil == User.by_login(username)
          add_error(:username, :exists, 'Username does not exist')
        end

        unless Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera does not exists')
        end

        if endpoints && endpoints.size == 0
          add_error(:endpoints, :size, 'Endpoints must contain at least one item')
        elsif endpoints
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
        camera = ::Camera.by_exid(inputs[:id])
        camera.name = name if name
        camera.owner = User.by_login(username) if username
        camera.is_public = is_public unless is_public.nil?
        camera.config.snapshots = inputs[:snapshots] if inputs[:snapshots]
        camera.timezone = timezone if timezone
        camera.save

        if inputs[:endpoints]
          inputs[:endpoints].each do |e|
            endpoint = URI.parse(e)

            camera.add_endpoint({
                                  scheme: endpoint.scheme,
                                  host: endpoint.host,
                                  port: endpoint.port
                                })

          end
          # fire off the evr.cm zone update to sidekiq
          primary = camera.endpoints.first
          DNSUpsertWorker.perform_async(id, primary.host)
        end

        camera
      end

    end
  end
end

