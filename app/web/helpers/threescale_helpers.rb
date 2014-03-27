module Evercam
  module ThreescaleHelpers

    def threescale_user_id(username)
      response = get_faraday_connection.get('/admin/api/accounts.xml', get_parameters)
      if !response.is_a?(Net::HTTPSuccess)
        raise Evercam::WebErrors::BadRequestError, response.body
      end
      document = Nokogiri::XML(response.body)
      elements = document.search("[text()*='#{username}']")
      element  = elements.first
      if element.nil?
        raise Evercam::WebErrors::BadRequestError, '3scale user not found'
      end
      element.parent.parent.parent.css('id').first.text
    end

    def threescale_signup(user, password)
      parameters = get_parameters.merge(org_name: user.fullname,
                                        username: user.username,
                                        email:    user.email,
                                        password: password)
      response   = get_faraday_connection.post('/admin/api/signup.xml', parameters)
      if !(200..299).include?(response.status)
        raise Evercam::WebErrors::BadRequestError, response.body
      end
      document     = Nokogiri::XML(response.body)
      user.api_id  = document.css('application_id').text
      user.api_key = document.css('key').text
      user.save
    end

    def threescale_signup_client(organization, user_name, email, password=nil)
      password ||= SecureRandom.hex(10)
      parameters = get_parameters.merge(org_name: organization,
                                        username: user_name,
                                        email:    email,
                                        password: password)
      response   = get_faraday_connection.post('/admin/api/signup.xml', parameters)
      if !(200..299).include?(response.status)
        raise Evercam::WebErrors::BadRequestError, response.body
      end
      document = Nokogiri::XML(response.body)
      {exid: document.xpath("/account/applications/application[1]/application_id").text,
       secret: document.xpath("/account/applications/application[1]/keys/key[1]").text,
       password: password}
    end

    def get_faraday_connection
      Faraday.new(Evercam::Config[:threescale][:url])
    end

    def get_base_parameters
      {provider_key: Evercam::Config[:threescale][:provider_key]}
    end

    def get_parameters(values={})
      get_base_parameters.merge(values)
    end
  end
end

