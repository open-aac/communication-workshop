module JsonApi::Token
  def self.as_json(token, user, args={})
    json = {}
    
    json['access_token'] = token
    json['token_type'] = 'bearer'
    json['user_name'] = user.settings['user_name']
    
    json
  end
end
