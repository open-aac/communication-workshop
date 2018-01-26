module JsonApi::Word
  extend JsonApi::Json
  
  TYPE_KEY = 'word'
  DEFAULT_PAGE = 50
  MAX_PAGE =100
    
  def self.build_json(word, args={})
    json = {}
    json['id'] = word.display_id
    json['word'] = word.word
    json['locale'] = word.locale
    json['pending'] = !word.id
    word.data ||= {}
    json['pending_revisions'] = (word.data['revisions'] || []).length > 0
    
    strings = ['border_color', 'background_color', 'description']
    objs = ['image']
    if args[:permissions]
      json['permissions'] = word.permissions_for(args[:permissions])
      if word.data
        # other data to include
        strings = WordData::STRING_PARAMS
        objs = WordData::OBJ_PARAMS
        json['related_identifiers'] = word.data['all_user_identifiers']
        json['approved_user_identifiers'] = word.data['approved_user_identifiers']
        json['revisions'] = word.data['revisions'] || []
      end
    end
    strings.each do |param|
      json[param] = word.data[param].to_s if word.data[param]
    end
    objs.each do |param|
      if word.data[param]
        if word.data[param].is_a?(Array)
          word.data[param].each do |obj|
            if obj['id'] && !obj['id'].match(/:/)
              obj['id'] = "#{word.global_id}:#{obj['id']}"
            end
          end
        end
        json[param] = word.data[param]
      end
    end
    
    json
  end
end
