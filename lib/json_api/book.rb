module JsonApi::Book
  extend JsonApi::Json
  
  TYPE_KEY = 'book'
  DEFAULT_PAGE = 25
  MAX_PAGE =50
    
  def self.build_json(book, args={})
    json = {}
    json['id'] = book.ref_id
    json['locale'] = book.locale
    json['pending'] = !book.id
    
    if args[:permissions] && book.data
#      json['permissions'] = badge.permissions_for(args[:permissions])
      # other data to include
      Book::STRING_PARAMS.each do |param|
        json[param] = book.data[param].to_s if book.data[param]
      end
      Book::OBJ_PARAMS.each do |param|
        json[param] = book.data[param] if book.data[param]
      end
    end
    json
  end
end
