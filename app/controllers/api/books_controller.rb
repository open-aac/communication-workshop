require 'json_api/book'
class Api::BooksController < ApplicationController
  def index
    books = Book.all.order('random_id')
    render json: JsonApi::Book.paginate(params, books)
  end
  
  def book_json
    book = Book.find_by_path(params['id'])
    return unless exists?(book, params['id'])
    return unless allowed?(book, 'view')
    render json: book.book_json
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
