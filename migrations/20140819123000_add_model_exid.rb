require 'stringex'

Sequel.migration do

  up do
    alter_table(:vendor_models) do
      add_column :exid, :text, null: false, default: ''
      add_column :jpg_url, :text, null: false, default: ''
      add_column :h264_url, :text, null: false, default: ''
      add_column :mjpg_url, :text, null: false, default: ''
      drop_column :known_models
    end

    used = []

    # convert each model name to exid and extract urls
    from(:vendor_models).each do |m|
      name = m[:name].to_url
      if name == 'default'
        v = from(:vendors).where(id: m[:vendor_id]).all.first
        name = "#{v[:exid]}_default"
      end

      if used.include?(name)
        name = name + '-2'
      end
      from(:vendor_models).where(id: m[:id]).
        update(
          exid: name,
          jpg_url: m[:config].fetch('snapshots', {}).fetch('jpg', ''),
          h264_url: m[:config].fetch('snapshots', {}).fetch('h264', ''),
          mjpg_url: m[:config].fetch('snapshots', {}).fetch('mjpg', '')
        )
      used.push(name)

    end

    alter_table(:vendor_models) do
      add_index [:exid], unique: true
    end

  end

  down do
    alter_table(:vendor_models) do
      drop_column :exid
      drop_column :jpg_url
      drop_column :h264_url
      drop_column :mjpg_url
    end
  end

end
