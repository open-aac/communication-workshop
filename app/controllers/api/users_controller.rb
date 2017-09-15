class Api::UsersController < ApplicationController
  def show
    if params['id'] == 'self' && !@api_user
      return api_erorr(400, {error: 'self id not valid without user session'})
    end
    id = params['id'] == 'self' ? (@api_user && @api_user.settings['user_name']) : params['id']
    if !id
      return api_error(400, {error: 'user id not specified'})
    end
    user = User.find_by_path(id)
    return unless exists?(user, id)
    return unless allowed?(user, 'view')
    render json: JsonApi::User.as_json(user, wrapper: true, permissions: @api_user)
  end
end
