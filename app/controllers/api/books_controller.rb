class Api::BooksController < ApplicationController
  def index
    # start with books that include current target words, if any
    # otherwise sort by stars, then title
    books = Book
    if !@api_user || !@api_user.admin?
      books = books.where(approved: true)
    end
    books = books.order('random_id')
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
      json = AccessibleBooks.find_json(params['url'])
    end
    if json
      json['image_url'] ||= ((json['pages'] || [])[0] || {})['image_url']
      render json: json
    else
      api_error(400, {error: 'id or valid url parameter required'})
    end
  end

  def print
    book = Book.find_by_path(params['book_id'])
    return unless exists?(book, params['book_id'])
    return unless allowed?(book, 'view')
    progress = Progress.schedule(PacketMaker, :generate_download, {:book_id => book.global_id})
    render json: JsonApi::Progress.as_json(progress, :wrapper => true)
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
    unless book.allows?(@api_user, 'link')
      if params['book']
        params['book'].delete('new_core_words')
      end
    end
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
