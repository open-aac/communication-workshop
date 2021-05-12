require 'user_mailer'

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
    if params['exists']
      render json: {user: {id: params['id']}}
      return
    end
    return unless allowed?(user, 'view')
    render json: JsonApi::User.as_json(user, wrapper: true, permissions: @api_user)
  end
  
  def index
    res = []
    if params['existing_id']
      user = User.find_by_path(params['existing_id'])
      res = [user] if user
    end
    render json: JsonApi::User.paginate(params, res)
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

  def external_usage
    if !ENV['COUGHDROP_CLIENT_ID'] || !ENV['COUGHDROP_CLIENT_SECRET']
      api_error(400, {error: 'coughdrop integration not defined'})
    elsif ENV['COUGHDROP_CLIENT_ID'] == params['integration_id'] && ENV['COUGHDROP_CLIENT_SECRET'] == params['integration_secret']
      if params['focus_id']
        if params['focus_id'].match(/^focus::/)
          focus = Focus.find_by_path(params['focus_id'].sub(/^focus::/, ''))
          if focus
            focus.data['usages'] = (focus.data['usages'] || 0) + 1
            focus.save
          end
        elsif params['focus_id'].match(/^book::/)
          book = Book.find_by_path(params['focus_id'].sub(/^book::/, ''))
          if book
            book.data['usages'] = (book.data['usages'] || 0) + 1
            book.save
          end
        end
      end
      render json: {accepted: true}
    else
      api_error(400, {error: 'invalid credentials'})
    end
  end

  def external_activities
    user_id = params['user_id']
    updates = params['updates']
    if !ENV['COUGHDROP_CLIENT_ID'] || !ENV['COUGHDROP_CLIENT_SECRET']
      api_error(400, {error: 'coughdrop integration not defined'})
    elsif ENV['COUGHDROP_CLIENT_ID'] == params['integration_id'] && ENV['COUGHDROP_CLIENT_SECRET'] == params['integration_secret']
      User.schedule(:process_external_activities, params['user_id'], 'coughdrop-anon', params['updates'])
      render json: {accepted: true}
    else
      api_error(400, {error: 'invalid credentials'})
    end
  end
  
  def create
    user = User.process_new(params['user'])
    if user.errored?
      api_error(400, {:errors => user.processing_errors})
    else
      UserMailer.deliver_message(:welcome, user.global_id)
      UserMailer.deliver_message(:new_user_registration, user.global_id)
      render json: JsonApi::User.as_json(user, wrapper: true)
    end
  end
  
  def forgot_password
    user = User.find_for_login(params['user_name'])
    email = user.settings['email'] if user && user.settings
    if !email
      render json: {sent: false}
      return
    end
    # TODO: ASYNC
    UserMailer.deliver_message(:forgot_password, User.where(:hashed_email => User.email_hash(email)).map(&:global_id)) if email
    render json: {sent: true}
  end
  
  def reset_password
    user = User.find_by_path(params['user_id'])
    return unless exists?(user, params['user_id'])
    res = user.update_password(params['token'], params['password'])
    render json: {reset: !!res}
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
