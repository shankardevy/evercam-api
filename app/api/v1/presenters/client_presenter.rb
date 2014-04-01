require_relative './presenter'

module Evercam
  module Presenters
    class Client < Presenter
    	expose :id,
    	       documentation: {desc: "The unique identifier for the client (also its API id).",
    	       	               required: true,
    	       	               type: String} do |client, options|
    		client.api_id
    	end

    	expose :callback_uris,
    	       documentation: {desc: "The callback URLs and host names accepted for the client.",
    	       	               required: true,
    	       	               type: String} do |client, options|
         client.callback_uris ? client.callback_uris.join(",") : ''
      end

    	expose :name,
    	       documentation: {desc: "The name of the client.",
    	       	               required: true,
    	       	               type: String}

    	expose :api_key,
    	       documentation: {desc: "The API key for the client.",
    	       	               required: true,
    	       	               type: String} do |client, options|
    	  client.api_key
    	end

      with_options(format_with: :timestamp) do
        expose :created_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at creation.',
          required: true
        }

        expose :updated_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at last update.',
          required: true
        }
      end
    end
  end
end