require 'json_api/word'

class Api::WordsController < ApplicationController
  def index
    words = WordData.all.order('random_id')
    render json: JsonApi::Word.paginate(params, words)
  end
  
  def show
    word = WordData.find_or_initialize_by_path(params['id'])
    return unless exists?(word, params['id'])
    return unless allowed?(word, 'view')
    render json: JsonApi::Word.as_json(word, wrapper: true, permissions: @api_user)
  end
  
  def update
    word = WordData.find_or_initialize_by_path(params['id'])
    return unless exists?(word, params['id'])
    return unless allowed?(word, 'edit')
    if word.process(params['word'], {'user' => @api_user})
      render json: JsonApi::Word.as_json(word, wrapper: true, permissions: @api_user)
    else
      api_error(400, {error: 'error saving word settings'})
    end
  end

  def destroy
    word = WordData.find_by_path(params['id'])
    return unless exists?(word, params['id'])
    return unless allowed?(word 'delete')
    word.destroy
    render json: JsonApi::Word.as_json(word, wrapper: true, permissions: @api_user)
  end
end
