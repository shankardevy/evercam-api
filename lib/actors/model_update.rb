module Evercam
  module Actors
    class ModelUpdate < Mutations::Command

      required do
        string :id
      end

      optional do
        string :name
        string :jpg_url, :empty => true
        string :mjpg_url, :empty => true
        string :mpeg4_url, :empty => true
        string :mobile_url, :empty => true
        string :h264_url, :empty => true
        string :lowres_url, :empty => true
        string :default_username, :empty => true
        string :default_password, :empty => true
      end

      def validate
        if VendorModel.where(exid: id).first.nil?
          add_error(:model, :exists, 'Model does not exist')
        end
      end

      def execute
        model = ::VendorModel.where(exid: inputs[:id]).first

        model.name = name if name
        # [:jpg, :mjpg, :mpeg4, :mobile, :h264, :lowres].each do |resource|
        #   url_name = "#{resource}_url"
        #   unless inputs[url_name].blank?
        #     inputs[url_name].prepend('/') if inputs[url_name][0,1] != '/'
        #     if model.values[:config].has_key?('snapshots')
        #       model.values[:config]['snapshots'].merge!({resource => inputs[url_name]})
        #     else
        #       model.values[:config].merge!({'snapshots' => { resource => inputs[url_name]}})
        #     end
        #   end
        # end

        # if inputs[:default_username] or inputs[:default_password]
        #   model.values[:config].merge!({'auth' => {'basic' => {'username' => inputs[:default_username].to_s.empty? ? '' : inputs[:default_username],
        #                                                         'password' => inputs[:default_password].to_s.empty? ? '' : inputs[:default_password]}}})
        # end

        model.save
        model
      end
    end
  end
end