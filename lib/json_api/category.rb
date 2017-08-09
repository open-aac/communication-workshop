module JsonApi::Category
  extend JsonApi::Json
  
  TYPE_KEY = 'category'
  DEFAULT_PAGE = 25
  MAX_PAGE =50
    
  def self.build_json(cat, args={})
    json = {}
    json['id'] = "#{cat.category}:#{cat.locale}"
    json['category'] = cat.category
    json['locale'] = cat.locale
    json['pending'] = !cat.id
    
    if args[:permissions] && cat.data
#      json['permissions'] = badge.permissions_for(args[:permissions])
      # other data to include
      WordCategory::STRING_PARAMS.each do |param|
        json[param] = cat.data[param].to_s if cat.data[param]
      end
      WordCategory::OBJ_PARAMS.each do |param|
        json[param] = cat.data[param] if cat.data[param]
      end
      json['related_identifiers'] = cat.data['all_user_identifiers']
    end
    json
  end
end
