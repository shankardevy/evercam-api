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

    s3 = AWS::S3.new(:access_key_id => Evercam::Config[:amazon][:access_key_id], :secret_access_key => Evercam::Config[:amazon][:secret_access_key])
    self.s3_bucket = s3.buckets['evercam-camera-assets']
  end
end
