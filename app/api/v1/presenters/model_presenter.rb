module Evercam
  class ModelPresenter

    def self.export(obj, opts={})
      {
        models: Array(obj).map do |md|
          {
            vendor: md.vendor.exid,
            name: md.name,
            known_models: md.known_models,
            defaults: md.config
          }
        end
      }
    end

  end
end

