require 'json_api/word'
require 'typhoeus'

class Api::WordsController < ApplicationController
  def index
    words = WordData.all
    if params['sort'] == 'recommended' && @api_user
      words = @api_user.related_words
    else
      words = words.order('random_id')
    end
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
    return unless allowed?(word, 'revise')
    if word.process(params['word'], {'user' => @api_user})
      render json: JsonApi::Word.as_json(word, wrapper: true, permissions: @api_user)
    else
      api_error(400, {error: 'error saving word settings'})
    end
  end
  
  def defaults
    if !@api_user
      return allows?(WordData.new, 'no_permission')
    end
    url = "https://app.mycoughdrop.com/api/v1/buttonsets/1_398"
    json = Rails.cache.fetch('default_word_settings', :expires_in => 6.hours) do
      res = Typhoeus.get(url)
      res.body
    end
    hash = JSON.parse(json)
    button = hash['buttonset']['buttons'].detect{|b| b['label'] == params['id']}
    if button
      res = Typhoeus.get("https://app.mycoughdrop.com/api/v1/search/parts_of_speech?q=morning&access_token=#{ENV['COUGHDROP_TOKEN']}")
      pos = JSON.parse(res.body) rescue nil
      render json: {
        background_color: button['background_color'],
        border_color: button['border_color'],
        parts_of_speech: pos && pos['types'] && pos['types'].join(','),
        image_url: button['image'],
        sentences: pos && pos['sentences'] && pos['sentences'].select{|s| s['approved'] }.map{|s| s['sentence'] }
      }
    else
      render api_error(404, {error: 'no button found'})
    end
  end
  
  def add
    word = WordData.find_or_initialize_by_path(params['id'])
    return unless exists?(@api_user, 'user_required')
    return unless exists?(word, params['id'])
    return unless allowed?(word, 'view')
    @api_user.add_word(word, params)
    render json: {added: true}
  end

  def remove
    word = WordData.find_or_initialize_by_path(params['id'])
    return unless exists?(@api_user, 'user_required')
    return unless exists?(word, params['id'])
    return unless allowed?(word, 'view')
    @api_user.remove_word(word, params)
    render json: {removed: true}
  end
  
  def suggestions
    return unless exists?(@api_user, 'user_required')
    hash = WordData.suggestions_for(@api_user)
    render json: hash
  end

  def destroy
    word = WordData.find_by_path(params['id'])
    return unless exists?(word, params['id'])
    return unless allowed?(word 'delete')
    word.destroy
    render json: JsonApi::Word.as_json(word, wrapper: true, permissions: @api_user)
  end
end
