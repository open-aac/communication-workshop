require 'json_api/book'
class Api::BooksController < ApplicationController
  def index
    # start with books that include current target words, if any
    # otherwise sort by stars, then title
    books = Book.all.order('random_id')
    render json: JsonApi::Book.paginate(params, books)
  end
  
  def book_json
    json = nil
    if params['id']
      book = Book.find_by_path(params['id'])
      return unless exists?(book, params['id'])
      return unless allowed?(book, 'view')
      json = book.book_json
    elsif params['url']
      if params['url'].match(Book::TARHEEL_REGEX)
        id = params['url'].match(Book::TARHEEL_REGEX)[1]
        url = Book.tarheel_json_url(id)
        res = Typhoeus.get(url)
        json = JSON.parse(res.body) rescue nil
        if json && json['title'] && json['pages']
          json['book_url'] = params['url']
          json['attribution_url'] = "https://tarheelreader.org/photo-credits/?id=#{id}"
          json['pages'].each_with_index do |page, idx|
            page['id'] ||= "page_#{idx}"
            page['image_url'] = page['url']
          end
        end
      else
        # TODO: do a GET request and look for valid JSON or a META tag to point to the json
      end
    end
    if json
      json['image_url'] ||= ((json['pages'] || [])[0] || {})['image_url']
      render json: json
    else
      api_error(400, {error: 'id or valid url parameter required'})
    end
  end
  
  def show
    book = Book.find_or_initialize_by_path(params['id'])
    return unless exists?(book, params['id'])
    return unless allowed?(book, 'view')
    render json: JsonApi::Book.as_json(book, wrapper: true, permissions: @api_user)
  end
  
  def update
    book = Book.find_or_initialize_by_path(params['id'])
    return unless exists?(book, params['id'])
    return unless allowed?(book, 'edit')
    if book.process(params['book'], {'user' => @api_user})
      render json: JsonApi::Book.as_json(book, wrapper: true, permissions: @api_user)
    else
      api_error(400, {error: 'error saving book settings'})
    end
  end
  
  def destroy
    book = Book.find_by_path(params['id'])
    return unless exists?(book, params['id'])
    return unless allowed?(book 'delete')
    book.destroy
    render json: JsonApi::Book.as_json(book, wrapper: true, permissions: @api_user)
  end
end
