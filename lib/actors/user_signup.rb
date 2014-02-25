module Evercam
  module Actors
    class UserSignup < Mutations::Command

      required do
        string :forename
        string :lastname
        string :username
        string :country
        string :email
      end

      def validate
        if User.by_login(username)
          add_error(:username, :exists, 'Username is already registered')
        end

        if User.by_login(email)
          add_error(:email, :exists, 'Email is already registered')
        end

        unless Country.by_iso3166(inputs[:country])
          add_error(:country, :invalid, 'Country is invalid')
        end
      end

      def execute
        country = Country.by_iso3166(inputs[:country])
        password = SecureRandom.hex(16)

        User.db.transaction do
          User.create(inputs.merge(password: password, country: country)).tap do |user|
            share_remembrance_camera(user)
            Mailers::UserMailer.confirm(user: user, password: password)
          end
        end
      end

      private

      def share_remembrance_camera(user)
        evercam_user = User[username: 'evercam']
        if !evercam_user.nil?
          camera = Camera.where(owner_id: evercam_user.id,
                                exid:     'evercam-remembrance-camera').first
          if !camera.nil?
            CameraShare.create(user: user, camera: camera,
                               kind: CameraShare::PUBLIC,
                               sharer: evercam_user)
          end
        end
      end

    end
  end
end

