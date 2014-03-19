module Evercam
   module SessionHelper
   	# This method provides convenient access to the Rack session object.
   	def session
   		(env["rack.session"] || {})
   	end
   end
end