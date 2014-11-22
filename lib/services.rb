require 'active_support/core_ext/module/attribute_accessors'

module Evercam
  module Services
    mattr_accessor :dalli_cache
    mattr_accessor :s3_bucket

    options = { :namespace => "app_v1", :compress => true, :expires_in => 300 }
    if ENV["MEMCACHEDCLOUD_SERVERS"]
      self.dalli_cache = Dalli::Client.new(ENV["MEMCACHEDCLOUD_SERVERS"].split(','), :username => ENV["MEMCACHEDCLOUD_USERNAME"], :password => ENV["MEMCACHEDCLOUD_PASSWORD"])
    else
      self.dalli_cache = Dalli::Client.new('127.0.0.1:11211', options)
    end

    if Evercam::Config.env == :development
      if !system('lsof -i:10453')
        system('2>/dev/null 1>&2 fakes3 --root=/tmp/fakes3 --port=10453 &')
        abort 'FakeS3 was not running and was started automatically, start the server again to continue'
      end
      s3 = AWS::S3.new(
        :access_key_id => Evercam::Config[:amazon][:access_key_id],
        :secret_access_key => Evercam::Config[:amazon][:secret_access_key],
        :s3_endpoint => 'localhost',
        :s3_force_path_style => true,
        :s3_port => 10453,
        :use_ssl => false
      )
      s3.buckets.create('evercam-camera-assets')
      self.s3_bucket = s3.buckets['evercam-camera-assets']
    else
      s3 = AWS::S3.new(
        :access_key_id => Evercam::Config[:amazon][:access_key_id],
        :secret_access_key => Evercam::Config[:amazon][:secret_access_key]
      )
      self.s3_bucket = s3.buckets['evercam-camera-assets']
    end
  end
end
