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
            is_public: st.is_public
          }.merge(st.config)
        end
      }
    end

  end
end

