require 'json_api/category'

class Api::CategoriesController < ApplicationController
  def index
    categories = WordCategory.where(:has_content => true)
    if params['sort'] == 'recommended' && @api_user
      categories = @api_user.related_categories
    elsif params['sort'] == 'alpha'
      categories = categories.order('category')
    else
      categories = categories.order('random_id').limit(50).to_a.sort_by{|w| rand }
    end
    render json: JsonApi::Category.paginate(params, categories)
  end
  
  def show
    category = WordCategory.find_or_initialize_by_path(params['id'])
    return unless exists?(category, params['id'])
    render json: JsonApi::Category.as_json(category, wrapper: true, permissions: @api_user)
  end
  
  def update
    category = WordCategory.find_or_initialize_by_path(params['id'])
    return unless exists?(category, params['id'])
    if category.process(params['category'], {'user' => @api_user})
      render json: JsonApi::Category.as_json(category, wrapper: true, permissions: @api_user)
    else
      api_error(400, {error: 'error saving category settings'})
    end
  end
end
