module JsonApi::Focus
  extend JsonApi::Json
  
  TYPE_KEY = 'focus'
  DEFAULT_PAGE = 25
  MAX_PAGE =50
    
  def self.build_json(focus, args={})
    json = {}
    json['id'] = focus.ref_id
    json['locale'] = focus.locale || 'en'
    json['pending'] = !focus.id
    json['approved'] = !!focus.approved
    json['title'] = focus.title
    json['category'] = focus.category
    if focus.data
      json['all_words'] = focus.data['all_words']
      json['words'] = focus.data['words']
      json['author'] = focus.data['author']
      json['helper_words'] = focus.data['helper_words'] || focus.related_page_words
      json['source_url'] = focus.data['source_url']
      json['image_url'] = focus.data['image_url']
    end
    # https://shared.tarheelreader.org/shared/read/i-like-strawberries
    
    if args.has_key?(:permissions) && focus.data
      json['permissions'] = focus.permissions_for(args[:permissions])
      json['approved_users'] = focus.approved_users
    end
    json
  end
end
