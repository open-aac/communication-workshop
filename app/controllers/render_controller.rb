class RenderController < ApplicationController
  def default
    if params['book_id']
      book = Book.find_by_path(params['book_id'])
      @meta_record = book if book
    end
  end
  
  def book; end
  
  def terms; end
  
  def privacy; end
end
