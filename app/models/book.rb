class Book < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Permissions

  secure_serialize :data
  before_save :generate_defaults
  
  add_permissions('view', ['*']) { true }
  add_permissions('edit', 'delete', ['*']) {|user| user.id == self.user_id || user.admin? }
  add_permissions('edit', 'delete', ['*']) {|user| !self.id }

  def generate_defaults
    self.data ||= {}
    self.random_id ||= (rand(9999999999) + Time.now.to_i)
    true
  end
  
  def self.find_or_initialize_by_path(str)
    res = self.find_by_path(str)
    if !res
      res = self.new
      res.ref_id = str
    end
    res
  end

  STRING_PARAMS = ['title', 'author', 'source_url']
  OBJ_PARAMS = ['pages', 'image']
  
  def process_params(params, user_params)
    self.generate_defaults
    STRING_PARAMS.each do |string_param|
      self.data[string_param] = self.process_string(params[string_param])
    end
    OBJ_PARAMS.each do |obj_param|
      self.data[obj_param] = params[obj_param]
    end
    self.user_id = user_params['user'].id if user_params['user']
  end
  
  def book_json
    book = self.data
    res = {
      'book_url' => "#{JsonApi::Json.current_host}/books/#{self.ref_id}",
      'author' => book['author'] || 'Unknown Author',
      'title' => book['title'] || 'Unnamed Book',
      'attribution_url' => "#{JsonApi::Json.current_host}/books/#{self.ref_id}",
      'pages' => [
        {
          'id' => 'title_page',
          'text' => book['title'] || 'Unnamed Book',
          'image_url' => (book['image'] || {})['image_url'],
          'image_content_type' => '',
          'image_attribution_type' => (book['image'] || {})['license'],
          'image_attribution_url' => (book['image'] || {})['license_url'],
          'image_attribution_author' => (book['image'] || {})['author']
        }
      ] 
    }
    (book['pages'] || []).each_with_index do |page, idx|
      res['pages'] << {
        'id' => "page_#{idx + 1}",
        'text' => page['text'],
        'image_url' => (page['image'] || {})['image_url'],
        'image_content_type' => '',
        'image_attribution_type' => (page['image'] || {})['license'],
        'image_attribution_url' => (page['image'] || {})['license_url'],
        'image_attribution_author' => (page['image'] || {})['author'],
        'image2_url' => (page['image2'] || {})['image_url'],
        'image2_content_type' => '',
        'image2_attribution_type' => (page['image2'] || {})['license'],
        'image2_attribution_url' => (page['image2'] || {})['license_url'],
        'image2_attribution_author' => (page['image2'] || {})['author'],
      }
    end
    res.to_json
  end
end
