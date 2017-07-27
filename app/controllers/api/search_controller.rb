require 'typhoeus'
class Api::SearchController < ApplicationController
  def books
    url = params['url']
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
        image_url: "https://tarheelreader.org#{data['pages'][1]['url']}",
        attribution: "https://tarheelreader.org/photo-credits/?id=#{data['ID']}",
      }
      render json: json
    end
  end
end
