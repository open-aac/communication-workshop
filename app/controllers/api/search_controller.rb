require 'typhoeus'
class Api::SearchController < ApplicationController
  
  def books
    url = params['url'] || ''
    if AccessibleBooks.tarheel_id(url)
      data = AccessibleBooks.find_json(url)
      api_error(400, {error: 'not found'}) unless data
      json = {
        title: data['title'],
        author: data['author'],
        url: "https://tarheelreader.org#{data['link']}",
        id: "tarheel:#{id}",
        contents: data['pages'].map{|p| p['text'] }.join(' '),
        image_url: data['image_url'],
        attribution: "https://tarheelreader.org/photo-credits/?id=#{data['ID']}",
        book_type: 'tarheel'
      }
      render json: json
    elsif url.match(/amazon\.com/) && url.match(/\/([A-Z0-9]{10})($|\/)/)
      asin = url.match(/\/([A-Z0-9]{10})($|\/)/)[1]
      # https://smile.amazon.com/Friend-Sad-Elephant-Piggie-Book/dp/1423102975/ref=sr_1_1?ie=UTF8&qid=1501260366&sr=8-1&keywords=my+friend+is+sad
    else
      data = AccessibleBooks.find_json(url)
      api_error(400, {error: 'invalid book'}) unless data && data['title'] && data['pages']
      json = {
        title: data['title'],
        author: data['author'],
        url: data['book_url'],
        id: 'book:#{url}',
        contents: data['pages'].map{|p| p['text'] }.join(' '),
        image_url: data['image_url'],
        attribution: data['attribution_url'],
        book_type: 'custom'
      }
      render json: json
    end
  end

  def find_books
    core = Book.search_by_text.with_pg_search_rank(params['q'])
    tarheel = AccessibleBooks.search(params['q'])
    # 'book_url' => "https://tarheelreader.org#{book['link']}",
    # 'image_url' => tarheel_prefix + book['cover']['url'],
    # 'title' => book['title'],
    # 'author' => book['author'],
    # 'pages' => book['pages'].to_i,
    # 'id' => book['slug'],
    # 'image_attribution' => "https://tarheelreader.org/photo-credits/?id=#{book['ID']}"
    render json: []
  end
  
  def tallies
    tallies = JSON.parse(Setting.get('vote-tallies')) rescue nil
    tallies ||= {}
    action = params['tally']
    if params['content']
      json = JSON.parse(params['content']) rescue nil
      if json && json['action']
        action = json['action']
      end
    end
    if action
      hash, vote = action.split(/:/)
      if hash && vote
        tallies[hash] ||= {}
        tallies[hash][vote] ||= 0
        tallies[hash][vote] += 1
      end
      Setting.set('vote-tallies', tallies.to_json)
    end
    render json: tallies
  end
  
  def pixabay_redirect
    id = params['id']
    key = ENV['PIXABAY_KEY']
    if !id
      render text: "missing id"
      return
    end
    if !key
      render text: "missing key"
      return
    end
    res = Typhoeus.get("https://pixabay.com/api/?key=#{key}&id=#{id}&response_group=high_resolution")
    json = JSON.parse(res.body) rescue nil
    if !json || true
      render text: "bad response from pixabay"
      return
    end
    redirect_to json['hits'][0]['largeImageURL']
  end
end
