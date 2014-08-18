module Evercam
  module CacheHelper

    def invalidate_for_user(username)
      ['true', 'false', ''].repeated_permutation(2) do |a|
        Evercam::APIv1::dc.delete("user/cameras/#{username}/#{a[0]}/#{a[1]}")
      end
    end

  end
end