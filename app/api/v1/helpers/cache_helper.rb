module Evercam
  module CacheHelper

    def invalidate_for_user(username)
      Evercam::APIv1::dc.delete("user/cameras/#{username}/true/true")
      Evercam::APIv1::dc.delete("user/cameras/#{username}/false/true")
      Evercam::APIv1::dc.delete("user/cameras/#{username}/true/false")
      Evercam::APIv1::dc.delete("user/cameras/#{username}/false/false")
    end

  end
end