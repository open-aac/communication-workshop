class Api::FocusController < ApplicationController
  def index
    focuses = nil
    if params['category']
      focuses = Focus.where(category: params['category']).order('title')
    else
      focuses = Focus.search_by_text(params['q'])
    end
    if params['locale']
      focuses = focuses.where(locale: params['locale'])
    end
    if !@api_user || !@api_user.admin?
      focuses = focuses.where(approved: true)
    end
    render json: JsonApi::Focus.paginate(params, focuses)
  end

  def show
    focus = Focus.find_or_initialize_by_path(params['id'])
    return unless exists?(focus, params['id'])
    return unless allowed?(focus, 'view')
    render json: JsonApi::Focus.as_json(focus, wrapper: true, permissions: @api_user)
  end
  
  def update
    focus = Focus.find_or_initialize_by_path(params['id'])
    return unless exists?(focus, params['id'])
    return unless allowed?(focus, 'edit')
    unless focus.allows?(@api_user, 'link')
      if params['focus']
        params['focus'].delete('new_core_words')
      end
    end
    if focus.process(params['focus'], {'user' => @api_user})
      render json: JsonApi::Focus.as_json(focus, wrapper: true, permissions: @api_user)
    else
      api_error(400, {error: 'error saving focus settings'})
    end
  end
  
  def destroy
    focus = Focus.find_by_path(params['id'])
    return unless exists?(focus, params['id'])
    return unless allowed?(focus 'delete')
    focus.destroy
    render json: JsonApi::Focus.as_json(focus, wrapper: true, permissions: @api_user)
  end
end
