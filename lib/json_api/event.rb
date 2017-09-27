module JsonApi::Event
  extend JsonApi::Json
  
  TYPE_KEY = 'event'
  DEFAULT_PAGE = 25
  MAX_PAGE =50
    
  def self.build_json(event, args={})
    json = {}
    json['id'] = event['unique_id']
    json['activity_id'] = event['activity_id']
    json['text'] = event['text']
    json['tracked'] = event['tracked']
    json['success_level'] = event['success_level'].to_i if event['success_level']
    json['notes'] = event['notes'] if event['notes']
    json['user_name'] = event['user_name']
    json['user_id'] = event['user_id']
    json
  end
end
