class WordData < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Revisions
  include Permissions

  secure_serialize :data
  before_save :generate_defaults

  add_permissions('view', ['*']) { true }
  add_permissions('edit', ['*']) {|user| !!user }
  add_permissions('delete') {|user| user.admin? }
  
  def generate_defaults
    self.data ||= {}
    self.random_id ||= (rand(9999999999) + Time.now.to_i)
    true
  end
  
  def self.find_or_initialize_by_path(str)
    res = self.find_by_path(str)
    if !res
      pieces = str.split(/:/, 2)
      return nil unless pieces.length == 2
      res = self.new
      res.word = CGI.unescape(pieces[0])
      res.locale = pieces[1]
    end
    res
  end
  
  STRING_PARAMS = ['border_color', 'background_color', 'description', 'parts_of_speech', 'verbs',
        'adjectives', 'pronouns', 'determiners', 'time_based_words', 'location_based_words',
        'other_words', 'related_categories', 'references']
  OBJ_PARAMS = ['image', 'usage_examples', 'level_1_modeling_examples', 'level_2_modeling_examples', 
        'level_3_modeling_examples', 'prompts', 'learning_projects', 'activity_ideas', 'books', 
        'topic_starters', 'videos', 'authors']
  
  def process_params(params, user_params)
    self.generate_defaults
    rev_params = {}
    if user_params['user']
      rev_params['user_identifier'] = user_params['user'].settings['user_name']
      rev_params['editable'] = self.allows?(user_params['user'], 'delete')
    end
    self.process_revisions(rev_params) do |hash|
      STRING_PARAMS.each do |string_param|
        hash[string_param] = self.process_string(params[string_param])
      end
      ['border_color', 'background_color'].each do |key|
        hash[key] = self.process_color(params[key]) if params[key]
      end
      OBJ_PARAMS.each do |obj_param|
        hash[obj_param] = params[obj_param]
      end
    end
    if user_params['user'] && self.allows?(user_params['user'], 'delete')
      if params['add_user_identifier']
        self.add_user_identifier(params['add_user_identifier'])
      end
    end
  end
end
