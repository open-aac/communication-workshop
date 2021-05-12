class RenderController < ApplicationController
  def default
    if params['book_id']
      book = Book.find_by_path(params['book_id'])
      if book
        book.data['views'] = (book.data['views'] || 0) + 1
        book.save
      end
      @meta_record = book if book
    elsif params['focus_id']
      focus = Focus.find_by_path(params['focus_id'])
      if focus
        focus.data['views'] = (focus.data['views'] || 0) + 1
        focus.save
      end
    end
  end
  
  def book
    if params['id']
      book = Book.find_by_path(params['book_id'])
      if book
        book.data['launches'] = (book.data['launches'] || 0) + 1
        book.save
      end
    end
  end
  
  def terms; end
  
  def privacy; end
end
