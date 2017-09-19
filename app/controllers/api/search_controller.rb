require 'typhoeus'
class Api::SearchController < ApplicationController
  def books
    url = params['url'] || ''
    if url.match(/https?:\/\/tarheelreader.org\/.+\/.+\/.+\/.+\//)
      id = url.match(/https?:\/\/tarheelreader.org\/.+\/.+\/.+\/(.+)\//)[1]
      url = "https://tarheelreader.org/book-as-json/?slug=#{CGI.escape(id)}"
      res = Typhoeus.get(url)
      data = JSON.parse(res.body) rescue nil
      api_error(400, {error: 'not found'}) unless data
      json = {
        title: data['title'],
        author: data['author'],
        url: "https://tarheelreader.org#{data['link']}",
        id: "tarheel:#{id}",
        contents: data['pages'].map{|p| p['text'] }.join(' '),
        image_url: "https://tarheelreader.org#{data['pages'][1]['url']}",
        attribution: "https://tarheelreader.org/photo-credits/?id=#{data['ID']}",
        book_type: 'tarheel'
      }
      render json: json
    elsif url.match(/amazon\.com/) && url.match(/\/([A-Z0-9]{10})($|\/)/)
      asin = url.match(/\/([A-Z0-9]{10})($|\/)/)[1]
      # https://smile.amazon.com/Friend-Sad-Elephant-Piggie-Book/dp/1423102975/ref=sr_1_1?ie=UTF8&qid=1501260366&sr=8-1&keywords=my+friend+is+sad
    else
      if url.match(/dropbox\.com/) && url.match(/\?dl=0$/)
        url = url.sub(/\?dl=0$/, '?dl=1')
      end
      res = Typhoeus.get(url)
      data = JSON.parse(res.body) rescue nil
      api_error(400, {error: 'invalid book'}) unless data && data['title'] && data['pages']
      json = {
        title: data['title'],
        author: data['author'],
        url: data['book_url'],
        id: 'book:#{url}',
        image_url: data['pages'][0]['image_url'],
        attribution: data['attribution_url'],
        book_type: 'custom'
      }
      render json: json
    end
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
end
