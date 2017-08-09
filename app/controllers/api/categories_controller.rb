require 'json_api/category'

class Api::CategoriesController < ApplicationController
  def index
    categories = WordCategory.all.order('random_id')
    render json: JsonApi::Category.paginate(params, categories)
  end
  
  def show
    category = WordCategory.find_or_initialize_by_path(params['id'])
    return unless exists?(category, params['id'])
    render json: JsonApi::Category.as_json(category, wrapper: true, permissions: {})
  end
  
  def update
    category = WordCategory.find_or_initialize_by_path(params['id'])
    return unless exists?(category, params['id'])
    if category.process(params['category'], {'user_editable' => true})
      render json: JsonApi::Category.as_json(category, wrapper: true, permissions: {})
    else
      api_error(400, {error: 'error saving category settings'})
    end
  end
end
