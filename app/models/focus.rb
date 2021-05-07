class Focus < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Permissions
  include PgSearch::Model
  include Revisions

  pg_search_scope :search_by_text, :against => :search_string
  secure_serialize :data
  before_save :generate_defaults

  add_permissions('view', ['*']) { true }
  add_permissions('edit', 'delete', ['*']) {|user| user.id == self.user_id || user.admin? }
  add_permissions('edit', 'delete', ['*']) {|user| !self.id }
  add_permissions('link') {|user| user.admin? }

  def generate_defaults
    self.data ||= {}
    str = (self.data['words'] || '') + "\n" + (self.data['helper_words'] || '')
    self.data['all_words'] = str.downcase.split(/\s+/).uniq.join(' ')
    self.search_string = (self.title || '') + "\n" + (self.data['author'] || '') + "\n" + str
    self.category ||= 'other'
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

  STRING_PARAMS = ['words', 'source_url', 'image_url', 'helper_words', 'author']
  OBJ_PARAMS = []
  
  def process_params(params, user_params)
    self.title = params['title']
    self.locale ||= params['locale']
    self.category = params['category']
    self.generate_defaults
    STRING_PARAMS.each do |string_param|
      self.data[string_param] = self.process_string(params[string_param])
    end
    OBJ_PARAMS.each do |obj_param|
      self.data[obj_param] = params[obj_param]
    end
    if params['approved']
      if user_params['user'] && self.allows?(user_params['user'], 'link')
        self.approved = true
        self.add_user_identifier(user_params['user'].identifier)
      end
    end
    self.user_id ||= user_params['user'].id if user_params['user']
  end
end
