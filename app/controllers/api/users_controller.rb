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
  
  def update
    user = User.find_by_path(params['id'])
    return unless exists?(user, params['id'])
    return unless allowed?(user, 'edit')
    user.process(params['user'])
    if user.errored?
      api_error(400, {:errors => user.processing_errors})
    else
      render json: JsonApi::User.as_json(user, wrapper: true, permissions: @api_user)
    end
  end
  
  def update_word_map
    user = User.find_by_path(params['user_id'])
    return unless exists?(user, params['user_id'])
    return unless allowed?(user, 'edit')
    res = false
    res = user.update_external_map if user.settings['external_tracking']
    render json: {updated: res}
  end
  
  def full_map
    user = User.find_by_path(params['user_id'])
    return unless exists?(user, params['user_id'])
    return unless allowed?(user, 'view')
    render json: user.full_map
  end
  
  def words
    user = User.find_by_path(params['user_id'])
    return unless exists?(user, params['user_id'])
    return unless allowed?(user, 'view')
    map = user.word_map
    render json: {
      words: user.settings['words'],
      word_map: map,
      linked_map_user_name: (map || {})['_user_name']
    }
  end
  
  def events
    user = @api_user
    return unless exists?(user)
#     user = User.find_by_path(params['user_id'])
#     return unless exists?(user, params['user_id'])
#     return unless allowed?(user, 'view')
    list = user.recent_activities
    render json: JsonApi::Event.paginate(params, list)
  end
end
