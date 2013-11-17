require 'sinatra'
require 'sinatra/flash'

module Evercam
  class WebApp < Sinatra::Base

    enable :sessions
    register Sinatra::Flash

    configure(:development) do
      set :session_secret, 'swordfish'
    end

  end
end

require_relative './routes/login'

