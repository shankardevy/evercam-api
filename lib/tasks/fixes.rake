task :fix_model, [:m, :jpg_url, :h264_url, :mjpg_url, :default_username, :default_password] do |t, args|
  args.with_defaults(:jpg_url => "", :h264_url => "", :mjpg_url => "", :default_username => "", :default_password => "")

  m = args.m
  jpg_url = args.jpg_url.nil? ? "" : args.jpg_url
  h264_url = args.h264_url.nil? ? "" : args.h264_url
  mjpg_url = args.mjpg_url.nil? ? "" : args.mjpg_url
  default_username = args.default_username.nil? ? "" : args.default_username.to_s
  default_password = args.default_password.nil? ? "" : args.default_password.to_s

  m.name = m.name.upcase

  if !jpg_url.blank?
    m.jpg_url = jpg_url
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('jpg')
        m.values[:config]['snapshots']['jpg'] = jpg_url
      else
        m.values[:config]['snapshots'].merge!({:jpg => jpg_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :jpg => jpg_url}})
    end
  end

  if !h264_url.blank?
    m.h264_url = h264_url
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('h264')
        m.values[:config]['snapshots']['h264'] = h264_url
      else
        m.values[:config]['snapshots'].merge!({:h264 => h264_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :h264 => h264_url}})
    end
  end

  if !mjpg_url.blank?
    m.mjpg_url = mjpg_url
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('mjpg')
        m.values[:config]['snapshots']['mjpg'] = mjpg_url
      else
        m.values[:config]['snapshots'].merge!({:mjpg => mjpg_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :mjpg => mjpg_url}})
    end
  end

  if default_username or default_password
    m.values[:config].merge!({
      'auth' => {
        'basic' => {
          'username' => default_username.to_s.empty? ? '' : default_username.to_s,
          'password' => default_password.to_s.empty? ? '' : default_password.to_s
        }
      }
    })
  end

  puts "       " + m.values[:config].to_s

  m.save

  puts "       FIXED: #{m.exid}"
end

task :fix_models_data do
  VendorModel.all.each do |model|
    updated = false
    ## Upcase all model names except Default
    if model.name.downcase != "default"
      if model.name != model.name.upcase
        model.name = model.name.upcase
        updated = true
      end
    end

    ## Remove None from model Urls
    if !model.jpg_url.blank? && (model.jpg_url.downcase == "none" || model.jpg_url.downcase == "jpg" || model.jpg_url.length < 4)
      model.jpg_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('jpg')
          model.values[:config]['snapshots']['jpg'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:jpg => ""})
          updated = true
        end
      end
    end
    if !model.h264_url.blank? && (model.h264_url.downcase == "none" || model.h264_url.downcase == "h264" || model.h264_url.length < 4)
      model.h264_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('h264')
          model.values[:config]['snapshots']['h264'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:h264 => ""})
          updated = true
        end
      end
    end
    if !model.mjpg_url.blank? && (model.mjpg_url.downcase == "none" || model.mjpg_url.downcase == "mjpg" || model.mjpg_url.length < 4)
      model.mjpg_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('mjpg')
          model.values[:config]['snapshots']['mjpg'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:mjpg => ""})
          updated = true
        end
      end
    end

    if updated
      puts " - " + model.name + ", " + model.exid
      model.save
    end
  end
end
