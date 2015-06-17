require 'nokogiri'
require 'digest/sha1'

module Evercam
  module Actors
    class UserSignup < Mutations::Command
      include ThreeScaleHelper

      required do
        string :firstname
        string :lastname
        string :username
        string :email
        string :password
      end

      optional do
        string :country
        string :share_request_key
      end

      def validate
        if (/^.+@.+\..+$/ =~ inputs[:email]).nil?
          add_error(:email, :invalid, 'Not a valid email address.')
        end

        if (inputs[:email] || "").length < 6
          add_error(:email, :invalid, 'Email is too short.')
        end

        if (inputs[:username] || "").length < 3
          add_error(:username, :invalid, 'User name is too short.')
        end
      end

      def execute
        country  = Country.by_iso3166(inputs[:country])
        password = inputs[:password]
        share_request_key = inputs[:share_request_key]
        inputs.delete("share_request_key")

        if country.nil?
          raise Evercam::NotFoundError.new("The country code "\
                                           "'#{inputs[:country]}'"\
                                           " is not valid.")
        end

        if User.where(username: inputs[:username]).count != 0
          raise Evercam::ConflictError.new("The '#{inputs[:username]}' user name is already registered.",
                                           "duplicate_username_error", inputs[:username])
        end

        if User.where(email: inputs[:email]).count != 0
          raise Evercam::ConflictError.new("The '#{inputs[:email]}' email address is already registered.",
                                           "duplicate_email_error", inputs[:email])
        end

        user = User.new(inputs.merge(password: password, country: country))
        if share_request_key.present?
          user.confirmed_at = Time.now
        end
        if !user.valid?
          raise Evercam::BadRequestError.new("Invalid parameters specified to request.",
                                             "invalid_parameters", *user.errors.keys)
        end

        User.db.transaction do
          user.save
          share_remembrance_camera(user)
          threescale_signup(user, password)
          if share_request_key.blank?
            code = Digest::SHA1.hexdigest(user.username + user.created_at.to_s)
            Mailers::UserMailer.confirm(user: user, code: code)
          end
        end

        # Create intercom user
        if Evercam::Config.env == :production
          intercom = Intercom::Client.new(
            app_id: Evercam::Config[:intercom][:app_id],
            api_key: Evercam::Config[:intercom][:api_key]
          )
          begin
            ic_user = intercom.users.find(:email => inputs[:email])
          rescue Intercom::ResourceNotFound
            # Ignore it
          end
          if ic_user.nil?
            # Create ic user
            begin
              intercom.users.create(
                :email => inputs[:email],
                :name => user.fullname,
                :signed_up_at => Time.now.to_i
              )
            rescue
              # Ignore it
            end
          end
        end
        user
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
