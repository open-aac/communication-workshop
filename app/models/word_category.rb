class WordCategory < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Revisions

  secure_serialize :data
  before_save :generate_defaults
  
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
      res.category = CGI.unescape(pieces[0])
      res.locale = pieces[1]
    end
    res
  end
  
  STRING_PARAMS = ['description', 'verbs',
        'adjectives', 'pronouns', 'determiners', 'time_based_words', 'location_based_words',
        'other_words', 'references']
  OBJ_PARAMS = ['image', 'age_range', 'level_1_modeling_examples', 'level_2_modeling_examples', 
        'level_3_modeling_examples', 'activity_ideas', 'books', 
        'videos', 'phrase_categories', 'authors']
  
  def process_params(params, user_params)
    self.generate_defaults
    self.process_revisions(user_params) do |hash|
      STRING_PARAMS.each do |string_param|
        self.data[string_param] = self.process_string(params[string_param])
      end
      OBJ_PARAMS.each do |obj_param|
        self.data[obj_param] = params[obj_param]
      end
    end
  end
end
