Sequel.migration do

  up do
    alter_table(:vendor_models) do
      add_column :resolution, :text, null: true, default: ''
      add_column :official_url, :text, null: true, default: ''
      add_column :audio_url, :text, null: true, default: ''
      add_column :more_info, :text, null: true, default: ''
      add_column :poe, :boolean, null: false, default: false
      add_column :wifi, :boolean, null: false, default: false
      add_column :onvif, :boolean, null: false, default: false
      add_column :psia, :boolean, null: false, default: false
      add_column :ptz, :boolean, null: false, default: false
      add_column :infrared, :boolean, null: false, default: false
      add_column :varifocal, :boolean, null: false, default: false
      add_column :sd_card, :boolean, null: false, default: false
      add_column :upnp, :boolean, null: false, default: false
      add_column :audio_io, :boolean, null: false, default: false
      add_column :discontinued, :boolean, null: false, default: false
    end
  end

  down do
    alter_table(:vendor_models) do
      drop_column :resolution
      drop_column :official_url
      drop_column :audio_url
      drop_column :more_info
      drop_column :poe
      drop_column :wifi
      drop_column :onvif
      drop_column :psia
      drop_column :ptz
      drop_column :infrared
      drop_column :varifocal
      drop_column :sd_card
      drop_column :upnp
      drop_column :audio_io
      drop_column :discontinued
    end
  end

end