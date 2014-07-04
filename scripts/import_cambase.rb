#! /usr/bin/env ruby

require 'dotenv'
require 'sequel'
require 'json'

Dotenv.load
Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)

require 'evercam_misc'
require 'evercam_models'
require 'active_support'
#Sequel::Model.db.loggers << Logger.new($stdout)
File.readlines('models.txt').each do |line|
  data = JSON.parse( line.gsub(/=>/, ': ') )
  vendor = Vendor.where(:exid => data['vendor']).first
  if vendor.nil?
    puts "Vendor #{data['vendor']} doesn't exist yet, creating it"
    vendor = Vendor.create(
      exid: data['vendor'],
      name: data['vendor'].capitalize,
      known_macs: ['']
    )
  end

  model = VendorModel.where(:vendor_id => vendor.id, :name => data['id']).first
  if model.nil?
    puts "Model #{data['id']} doesn't exist yet, adding it"
    VendorModel.create(
      vendor_id: vendor.id,
      name: data['id'],
      config: {:snapshots => data['snapshots']},
      known_models: '{}'
    )
  else
    puts "Model #{data['id']} already exist, skipping it"
  end
end


