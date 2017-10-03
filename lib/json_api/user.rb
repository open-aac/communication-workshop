module JsonApi::User
  extend JsonApi::Json
  
  TYPE_KEY = 'user'
  DEFAULT_PAGE = 25
  MAX_PAGE =50
    
  def self.build_json(user, args={})
    json = {}
    json['id'] = user.global_id
    json['user_name'] = user.settings['user_name']
    json['name'] = user.settings['name']
    json['admin'] = user.admin?
    
    if args[:permissions]
      json['permissions'] = user.permissions_for(args[:permissions])
      if json['permissions']['view']
        json['current_words'] = user.current_words
        json['created'] = user.created_at
        json['starred_activity_ids'] = user.settings['starred_activity_ids']
        json['external_tracking'] = user.settings['external_tracking']
        json['external_account'] = user.settings['external_account']
        json['modeling_level'] = user.settings['modeling_level']
        json['focus_length'] = user.settings['focus_length']
      end
    end
    
    json
  end
end
