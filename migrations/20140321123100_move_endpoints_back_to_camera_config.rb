require 'evercam_misc'
require 'evercam_models'

Sequel.migration do

  up do
    # convert each cameras endpoints to a record
    cameras = Camera.all

    if cameras.empty? then

      cameras.each do |c|
        c.endpoints.each do |e|
          if e.public?
            c.values[:config].merge!({'external_host' => e.host})
            c.values[:config].merge!({'external_http_port' => e.port})
          else
            c.values[:config].merge!({'internal_host' => e.host})
            c.values[:config].merge!({'internal_http_port' => e.port})
          end
        end
      
        c.save
      end

    end # end if cameras atrt not empty
  end


end

