require 'json_api/word'

class Api::WordsController < ApplicationController
  def index
    words = WordData.all.order('random_id')
    render json: JsonApi::Word.paginate(params, words)
  end
  
  def show
    word = WordData.find_or_initialize_by_path(params['id'])
    return unless exists?(word, params['id'])
    render json: JsonApi::Word.as_json(word, wrapper: true, permissions: {})
  end
  
  def update
    word = WordData.find_or_initialize_by_path(params['id'])
    return unless exists?(word, params['id'])
    if word.process(params['word'])
      render json: JsonApi::Word.as_json(word, wrapper: true, permissions: {})
    else
      api_error(400, {error: 'error saving word settings'})
    end
  end
end
