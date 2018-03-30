class Api::ImagesController < ApplicationController
  def show
    # return the URL or data URI for the image
    # if the image is still a data URI, re-schedule download
    # redirect or render in response
    image = UserImage.find_by_path(params['id'])
    return unless allowed?(image, 'view')
    if params['render']
      if !image
        render text: ""
      elsif image.redirect_url
        redirect_to image.redirect_url
      elsif image.data_uri_parts
        parts = image.data_uri_parts
        send_data parts[:binary], :type => parts[:type], :disposition => 'inline'
      else
        render text: ""
      end
    else
      render json: JsonApi::Image.as_json(image, wrapper: true, permissions: @api_user)
    end
  end
  
  def create
    # specify source URL/dataURI, schedule download, and return a proxy URL
    # optionally try to find an existing image that matches the URL
    image = UserImage.new
    return unless allowed?(image, 'edit')
    if image.process(params['image'], {'user' => @api_user})
      render json: JsonApi::Image.as_json(image, wrapper: true, permissions: @api_user)
    else
      api_error(400, {error: 'error saving image settings'})
    end
  end
end
