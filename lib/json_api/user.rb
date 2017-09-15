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
      end
    end
    
    json
  end
end
