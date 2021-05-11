module JsonApi::Book
  extend JsonApi::Json
  
  TYPE_KEY = 'book'
  DEFAULT_PAGE = 25
  MAX_PAGE =50
    
  def self.build_json(book, args={})
    json = {}
    json['id'] = book.ref_id
    json['locale'] = book.locale || 'en'
    json['pending'] = !book.id
    json['approved'] = !!book.approved
    json['public'] = !!book.public
    if book.data
      json['title'] = book.data['title']
      json['author'] = book.data['author']
      json['related_words'] = book.data['related_words'] || book.related_page_words
      json['total_pages'] = book.data['pages'].length
    end
    json['image'] = book.data['image']
    
    if args.has_key?(:permissions) && book.data
      json['permissions'] = book.permissions_for(args[:permissions])
      # other data to include
      Book::STRING_PARAMS.each do |param|
        json[param] = book.data[param].to_s if book.data[param]
      end
      Book::OBJ_PARAMS.each do |param|
        json[param] = book.data[param] if book.data[param]
      end
      json['pages'].each do |page|
        page['target_words'] = page['related_words'].split(/,|\n/).map(&:strip) if page['related_words']
      end
    end
    json
  end
end
