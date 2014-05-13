require_relative '../presenters/log_presenter'

module Evercam
  class V1LogRoutes < Grape::API

    include WebErrors

    DEFAULT_LIMIT = 20

    before do
      authorize!
    end

    desc 'Returns list of logs for given camera'
    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
      optional :limit, type: Integer, desc: "Number of results per page. Defaults to #{DEFAULT_LIMIT}."
      optional :page, type: Integer, desc: "Page number, starting from 0"
      optional :types, type: String, desc: "Comma separated list of log types: created, accessed, edited, viewed, captured", default: ''
      optional :objects, type: Boolean, desc: "Return objects instead of strings", default: false
    end
    get '/cameras/:id/logs' do
      camera = nil
      if Camera.is_mac_address?(params[:id])
        camera = camera_for_mac(caller, params[:id])
      else
        camera = Camera.where(exid: params[:id]).first
      end
      raise(Evercam::NotFoundError, "Camera not found") if camera.nil?
      limit = params[:limit] || DEFAULT_LIMIT
      page = params[:page] || 0
      page = 0 if page < 0
      limit = DEFAULT_LIMIT if limit < 1
      types = params[:types].split(',').map(&:strip)
      results = camera.activities
      results = results.where(:action => types) unless types.blank?
      results = results.limit(limit, page*limit).all
      total_pages = camera.activities.count / limit
      if params[:objects]
        present(Array(results), with: Presenters::Log).merge!({
            :camera_exid => camera.exid,
            :camera_name => camera.name,
            :pages => total_pages
          })
      else
        {
          logs: results,
          pages: total_pages
        }
      end
    end

  end
end

