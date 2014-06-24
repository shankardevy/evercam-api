#! /usr/bin/env ruby
# This scripts checks for invalid cameras after validation change

require 'dotenv'
require 'sequel'

Dotenv.load
Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)

require 'evercam_misc'
require 'evercam_models'
require 'active_support'

Camera.all.each do |c|
  unless c.valid?
    puts c.errors
    puts c.exid
    puts c.name
    puts "------------"
  end
end