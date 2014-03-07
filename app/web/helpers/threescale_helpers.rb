module Evercam
  module ThreescaleHelpers

    def threescale_user_id(username)
      uri = URI(Evercam::Config[:threescale][:url] + 'admin/api/accounts.xml')
      uri.query = URI.encode_www_form({'provider_key' => Evercam::Config[:threescale][:provider_key]})
      res = Net::HTTP.get_response(uri)
      unless res.is_a?(Net::HTTPSuccess)
        raise Evercam::WebErrors::BadRequestError, res.body
      end
      xml_doc  = Nokogiri::XML(res.body)
      els = xml_doc.search("[text()*='#{username}']")
      el = els.first
      if el.nil?
        raise Evercam::WebErrors::BadRequestError, '3scale user not found'
      end
      el.parent.parent.parent.css('id').first.text
    end

    def threescale_signup(user, password)
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

