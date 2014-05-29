#! /usr/bin/env ruby

require 'dotenv'
require 'sequel'

Dotenv.load
Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)

require 'evercam_misc'
require 'evercam_models'
require 'active_support'

Camera.all.each do |c|
  if c.config.fetch('auth', {}).nil?
    c.values[:config].delete('auth')
    c.save
    c.reload
  end
end