module JsonApi::Image
  extend JsonApi::Json
  
  TYPE_KEY = 'image'
  DEFAULT_PAGE = 25
  MAX_PAGE =50
    
  def self.build_json(image, args={})
    json = {}
    json['id'] = image.global_id
    json['url'] = image.settings['processed_url']
    json['url'] ||= "#{JsonApi::Json.current_host}/api/v1/images/#{image.global_id}?render=1"

    json
  end
end
