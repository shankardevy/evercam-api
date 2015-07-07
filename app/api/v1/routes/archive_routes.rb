require_relative '../presenters/archive_presenter'
require 'pry'

module Evercam
  class V1ArchiveRoutes < Grape::API
    include WebErrors

    resource :cameras do
      before do
        authorize!
      end

      #-------------------------------------------------------------------------
      # GET /v1/cameras/:id/archives
      #-------------------------------------------------------------------------
      desc 'Returns available archives for the camera',{
        entity: Evercam::Presenters::Archive
      }
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
      end
      get '/:id/archives' do
        camera = Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        unless rights.allow?(AccessRight::LIST)
          raise AuthorizationError.new if camera.is_public?
          if !rights.allow?(AccessRight::VIEW) && !camera.is_public?
            raise NotFoundError.new
          end
        end
        archives = Archive.where(camera_id: camera.id)
        present Array(archives), with: Presenters::Archive
      end

      #-------------------------------------------------------------------------
      # GET /v1/cameras/:id/archives/archive_id
      #-------------------------------------------------------------------------
      desc 'Returns available archives for the camera',{
                                                        entity: Evercam::Presenters::Archive
                                                      }
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
        requires :archive_id, type: String, desc: 'The unique identifier for the clip.'
      end
      get '/:id/archives/archive_id' do
        camera = Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        unless rights.allow?(AccessRight::LIST)
          raise AuthorizationError.new if camera.is_public?
          if !rights.allow?(AccessRight::VIEW) && !camera.is_public?
            raise NotFoundError.new
          end
        end
        archive = Archive.where(exid: params[:archive_id])
        if archive.count == 0
          raise NotFoundError.new("The '#{params[:archive_id]}' clip does not exist.")
        end
        present Array(archive), with: Presenters::Archive
      end

      #-------------------------------------------------------------------------
      # POST /v1/cameras/:id/archives
      #-------------------------------------------------------------------------
      desc 'Returns available archives for the camera',{
        entity: Evercam::Presenters::Archive
      }
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
        requires :title, type: String, desc: 'Clip title'
        requires :from_date, type: String, desc: 'Clip start timestamp, formatted as either Unix timestamp or ISO8601.'
        requires :to_date, type: String, desc: 'Clip end timestamp, formatted as either Unix timestamp or ISO8601.'
        requires :requested_by, type: String, desc: 'The unique identifier for the user who requested clip.'
        optional :embed_time, type: 'Boolean', desc: 'Overlay recording time'
        optional :public, type: 'Boolean', desc: 'Available publically'
      end
      post '/:id/archives' do
        camera = Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        unless rights.allow?(AccessRight::LIST)
          raise AuthorizationError.new if camera.is_public?
          if !rights.allow?(AccessRight::VIEW) && !camera.is_public?
            raise NotFoundError.new
          end
        end
        binding.pry
        outcome = Actors::ArchiveCreate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present Array(outcome.result), with: Presenters::Archive
      end
    end
  end
end