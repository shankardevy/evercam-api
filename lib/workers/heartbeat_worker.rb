$db = Sequel.connect('postgres://localhost/evercam_dev')

class HeartBeatWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(id)
    endpoints = $db[:camera_endpoints]
    online = false
    endpoints.where(:id => id).each do |row|
      begin
        uri = URI(row[:scheme] + '://' + row[:host] + ':' + row[:port].to_s)
        if Net::HTTP.get_response(uri).kind_of? Net::HTTPOK
          online = true
          break
        end
      rescue Exception
        # offline
      end
    end
    camera = $db[:cameras]
    if online
      camera.where(:id => id).update(:is_online => true)
    else
      camera.where(:id => id).update(:is_online => false)
    end
    camera.where(:id => id).update(:polled_at =>  Sequel.function(:NOW))
  end
end