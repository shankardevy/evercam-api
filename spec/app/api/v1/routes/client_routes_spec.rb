require 'rack_helper'
require_app 'api/v1'

describe 'API routes/client' do
   let(:app) {
   	Evercam::APIv1
   }

	describe 'POST /v1/client' do
		let(:parameters) {
			{name: "Client #{Time.now.to_i}",
		    user_name: "client_#{Time.now.to_i}",
		    email: "no.one@nowhere.com",
		    password: "password",
		    callback_uris: ["www.blah.com", "https://www.other.com"].join(",")}
		}

		let!(:client) {
			create(:client)
		}

		let(:api_keys) {
			{api_id: client.api_id, api_key: client.api_key}
		}

		context 'when given a correct set of parameters' do
			before(:each) do
				stub_request(:post, "https://evercam-admin.3scale.net/admin/api/signup.xml").
               with(:body => {"email"=>"no.one@nowhere.com", "org_name"=>parameters[:name], "password"=>"password", "provider_key"=>"b25bc9166b8805fc26a96f1130578d2b", "username"=>parameters[:user_name]},
              :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/x-www-form-urlencoded', 'User-Agent'=>'Faraday v0.9.0'}).
              to_return(:status => 201,
              	         :body => "<account>\n<id>123456789012345</id><applications>\n<application>\n<application_id>6261dee8</application_id>\n<keys>\n<key>a31505fce7268dfa702e31cb290a1f73</key>\n</keys>\n</application>\n</applications>\n</account>",
              	         :headers => {})
			end

			it 'returns success and creates a new client record' do
            post('/client', parameters.merge(api_keys))
            expect(last_response.status).to eq(201)
            data = last_response.json
            expect(data.include?("id")).to eq(true)
            expect(data.include?("api_key")).to eq(true)
            client = Client.where(api_id: data["id"]).first
            expect(client).not_to be_nil
            expect(client.api_key).to eq(data["api_key"])
            expect(client.callback_uris.include?("www.blah.com"))
            expect(client.callback_uris.include?("https://www.other.com"))
            expect(client.settings).to eq({"3Scale" => {"account_id" => "123456789012345",
                                                        "email"      => parameters[:email],
                                                        "user_name"  => parameters[:user_name]}})
         end
      end

		context 'when a name parameter is not specified' do
			it 'returns a parmameters error' do
				parameters.delete(:name)
				post('/client', parameters.merge(api_keys))
				expect(last_response.status).to eq(400)
				data = last_response.json
				expect(data.include?("message"))
				expect(data["message"]).to eq("name is missing")
			end
		end

		context 'when a user name parameter is not specified' do
			it 'returns a parmameters error' do
				parameters.delete(:user_name)
				post('/client', parameters.merge(api_keys))
				expect(last_response.status).to eq(400)
				data = last_response.json
				expect(data.include?("message"))
				expect(data["message"]).to eq("user_name is missing")
			end
		end

		context 'when an email parameter is not specified' do
			it 'returns a parmameters error' do
				parameters.delete(:email)
				post('/client', parameters.merge(api_keys))
				expect(last_response.status).to eq(400)
				data = last_response.json
				expect(data.include?("message"))
				expect(data["message"]).to eq("email is missing")
			end
		end

		context 'when a callback URIs parameter is not specified' do
			it 'returns a parmameters error' do
				parameters.delete(:callback_uris)
				post('/client', parameters.merge(api_keys))
				expect(last_response.status).to eq(400)
				data = last_response.json
				expect(data.include?("message"))
				expect(data["message"]).to eq("callback_uris is missing")
			end
		end

		context 'when not authenticated' do
			it 'returns an unauthenticated error' do
				post('/client', parameters)
				expect(last_response.status).to eq(401)
				data = last_response.json
				expect(data.include?("message"))
				expect(data["message"]).to eq("Unauthenticated")
			end
		end
	end

	describe 'GET /v1/client/:id' do
		let!(:client) {
			create(:client)
		}

		let(:api_keys) {
			{api_id: client.api_id, api_key: client.api_key}
		}

		context 'when given proper parameters' do
			it 'returns correct details for the client' do
				get("/client/#{client.api_id}", api_keys)
				expect(last_response.status).to eq(200)
				data = last_response.json
				expect(data.include?("id")).to eq(true)
				expect(data.include?("callback_uris")).to eq(true)
				expect(data.include?("name")).to eq(true)
				expect(data.include?("api_key")).to eq(true)
				expect(data.include?("created_at")).to eq(true)
				expect(data.include?("updated_at")).to eq(true)
				expect(data["id"]).to eq(client.api_id)
				expect(data["callback_uris"]).to eq(client.callback_uris.join(","))
				expect(data["name"]).to eq(client.name)
				expect(data["api_key"]).to eq(client.api_key)
				expect(data["created_at"]).to eq(client.created_at.to_i)
				expect(data["updated_at"]).to eq(client.updated_at.to_i)
			end
		end

		context 'when not given a client id' do
			it 'returns a parameter error' do
				get("/client", api_keys)
				expect(last_response.status).to eq(405)
			end
		end

		context 'when given a client id for a client that does not exist' do
			it 'returns a not found error' do
				get("/client/does_not_exist", api_keys)
				expect(last_response.status).to eq(404)
				data = last_response.json
				expect(data.include?("message"))
				expect(data["message"]).to eq("Not Found")
			end
		end

		context 'when not authenticated' do
			it 'returns an unauthenticated error' do
				get("/client/does_not_exist", {})
				expect(last_response.status).to eq(401)
				data = last_response.json
				expect(data.include?("message"))
				expect(data["message"]).to eq("Unauthenticated")
			end
		end
	end

	describe 'DELETE /v1/client/:id' do
		let!(:client) {
			create(:client)
		}

		let(:api_keys) {
			{api_id: client.api_id, api_key: client.api_key}
		}

      context 'when given the proper parameters' do
      	it 'returns success and deletes the client record' do
      		delete("/client/#{client.api_id}", api_keys)
      		expect(last_response.status).to eq(200)
      		expect(Client.where(api_id: client.api_id).count).to eq(0)
      	end
      end

      context 'when not given a client id' do
      	it 'returns a parameter error' do
				delete("/client", api_keys)
				expect(last_response.status).to eq(405)
      	end
      end

      context 'when given a client id for a client that does not exist' do
      	it 'returns success' do
				delete("/client/does_not_exist", api_keys)
				expect(last_response.status).to eq(200)
      	end
      end

      context 'when not authenticated' do
      	it 'returns an unauthenticated error' do
				delete("/client/does_not_exist", {})
				expect(last_response.status).to eq(401)
				data = last_response.json
				expect(data.include?("message"))
				expect(data["message"]).to eq("Unauthenticated")
      	end
      end
	end

	describe 'PATCH /v1/client/:id' do
		let!(:client) {
			create(:client)
		}

		let(:api_keys) {
			{api_id: client.api_id, api_key: client.api_key}
		}

		let(:parameters) {
			{name: "The Changed Client Name",
			 callback_uris: ["https://www.blah.ie", "www.middenhiem.com", "www.noodles.com"].join(",")}
		}

      context 'when given the proper parameters' do
      	it 'returns success and updates the client record' do
      		patch("/client/#{client.api_id}", parameters.merge(api_keys))
      		expect(last_response.status).to eq(200)
      		client.reload
      		expect(client.name).to eq(parameters[:name])
      		expect(client.callback_uris.join(",")).to eq(parameters[:callback_uris])
      	end
      end

      context 'when not given a client id' do
      	it 'returns a parameter error' do
      		patch("/client", parameters.merge(api_keys))
      		expect(last_response.status).to eq(405)
      	end
      end

      context 'when given a client id for a client that does not exist' do
      	it 'returns a not found error' do
      		patch("/client/does_not_exist", parameters.merge(api_keys))
      		expect(last_response.status).to eq(404)
      		data = last_response.json
      		expect(data.include?("message"))
      		expect(data["message"]).to eq("Not Found")
      	end
      end

      context 'when not authenticated' do
      	it 'returns an unauthenticated error' do
      		patch("/client/does_not_exist", parameters)
      		expect(last_response.status).to eq(401)
      		data = last_response.json
      		expect(data.include?("message"))
      		expect(data["message"]).to eq("Unauthenticated")
      	end
      end
	end
end