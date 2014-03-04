require 'nokogiri'
require_relative '../errors/web'

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

        if inputs[:email].length < 5
          # 3scale stuff, remove later
          add_error(:email, :invalid, 'Email is too short')
        end
      end

      def execute
        country = Country.by_iso3166(inputs[:country])
        password = SecureRandom.hex(16)

        User.db.transaction do
          User.create(inputs.merge(password: password, country: country)).tap do |user|
            share_remembrance_camera(user)
            three_scale(user, password)
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

      def three_scale(user, password)
        uri = URI(Evercam::Config[:threescale][:url] + 'admin/api/signup.xml')
        res = Net::HTTP.post_form(uri,
                                  'provider_key' => Evercam::Config[:threescale][:provider_key],
                                  'org_name' => user.fullname,
                                  'username' => user.username,
                                  'email' => user.email,
                                  'password' => password,
        )
        unless res.is_a?(Net::HTTPSuccess)
          raise Evercam::WebErrors::BadRequestError, 'Failed to create 3scale account'
        end
        xml_doc  = Nokogiri::XML(res.body)
        user.api_id = xml_doc.css('application_id').text
        user.api_key = xml_doc.css('key').text
        user.save
      end

    end
  end
end

