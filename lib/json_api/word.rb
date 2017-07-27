module JsonApi::Word
  extend JsonApi::Json
  
  TYPE_KEY = 'word'
  DEFAULT_PAGE = 25
  MAX_PAGE =505
    
  def self.build_json(word, args={})
    json = {}
    json['id'] = "#{word.word}:#{word.locale}"
    json['word'] = word.word
    json['locale'] = word.locale
    json['pending'] = !word.id
    
    if args[:permissions] && word.data
#      json['permissions'] = badge.permissions_for(args[:permissions])
      # other data to include
      WordData::STRING_PARAMS.each do |param|
        json[param] = word.data[param].to_s if word.data[param]
      end
      WordData::OBJ_PARAMS.each do |param|
        json[param] = word.data[param] if word.data[param]
      end
    end
    json
  end
end
