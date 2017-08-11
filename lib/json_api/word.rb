module JsonApi::Word
  extend JsonApi::Json
  
  TYPE_KEY = 'word'
  DEFAULT_PAGE = 25
  MAX_PAGE =50
    
  def self.build_json(word, args={})
    json = {}
    json['id'] = "#{word.word}:#{word.locale}"
    json['word'] = word.word
    json['locale'] = word.locale
    json['pending'] = !word.id
    
    if args[:permissions]
      json['permissions'] = word.permissions_for(args[:permissions])
      if word.data
        # other data to include
        WordData::STRING_PARAMS.each do |param|
          json[param] = word.data[param].to_s if word.data[param]
        end
        WordData::OBJ_PARAMS.each do |param|
          json[param] = word.data[param] if word.data[param]
        end
        json['related_identifiers'] = word.data['all_user_identifiers']
        json['approved_user_identifiers'] = word.data['approved_user_identifiers']
        json['revisions'] = word.data['revisions'] || []
      end
    end
    json
  end
end
