#!/usr/bin/env ruby

require File.expand_path('../../../lib/models', __FILE__)
db = Sequel::Model.db

db[:streams_old].each do |s|

  d = db[:devices].where(id: s[:device_id]).first
  f = db[:firmwares].where(id: d[:firmware_id]).first

  remap = {
    id: s[:id],
    created_at: s[:created_at],
    updated_at: s[:updated_at],

    name: s[:name],
    firmware_id: d[:firmware_id],
    owner_id: s[:owner_id],
    is_public: s[:is_public],

    config: Sequel.pg_json({
      endpoints: [d[:internal_uri], d[:external_uri]],
      snapshots: { jpg: s[:snapshot_path] },
      auth: f[:config]['auth'].deep_merge((d[:config] || {})['auth'] || {})
    })
  }

  puts remap.inspect
  db[:streams] << remap

end

