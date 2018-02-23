class Api::ProgressController < ApplicationController
  def progress
    progress = Progress.find_by_global_id(params['id'])
    return unless exists?(progress)
    return unless allowed?(progress, 'view')
    render json: JsonApi::Progress.as_json(progress, :wrapper => true).to_json
  end
end