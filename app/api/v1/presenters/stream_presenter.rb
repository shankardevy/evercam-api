module Evercam
  class StreamPresenter

    def self.export(obj, opts={})
      {
        streams: Array(obj).map do |st|
          {
            id: st.name,
            owner: st.owner.username,
            created_at: st.created_at.to_i,
            updated_at: st.updated_at.to_i,
            endpoints: [st.device.external_uri],
            is_public: st.is_public,
            snapshots: {
              jpg: st.snapshot_path
            }
          }.merge(st.device.config)
        end
      }
    end

  end
end

