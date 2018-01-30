class WordCategory < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Revisions
  include Permissions

  secure_serialize :data
  before_save :generate_defaults
  after_save :update_related_words
  
  add_permissions('view', ['*']) { true }
  add_permissions('revise', ['*']) {|user| !!user }
  add_permissions('edit', 'delete') {|user| user.admin? }

  def generate_defaults
    self.data ||= {}
    self.random_id ||= (rand(9999999999) + Time.now.to_i)
    true
  end
  
  def linked_words
    words = []
    WORD_TYPES.each do |list|
      words += (self.data[list] || '').split(/\,/).map(&:strip)
    end
    records = WordData.where(:locale => self.locale, :word => words)
  end
  
  def update_related_words
    return if @skip_related_update
    
    records = linked_words
    records.each do |word|
      if word.data  
        orig = word.data['related_categories']
        word.data['related_categories'] ||= ""
        list = word.data['related_categories'].split(/,/).map(&:strip)
        list << self.category
        word.data['related_categories'] = list.uniq.join(', ')
        word.instance_variable_set('@skip_related_update', true)
        word.save if word.data['related_categories'] != orig
        word.instance_variable_set('@skip_related_update', false)
      end
    end
  end
  
  def self.assert_word_relations
    WordData.all.each{|w| w.update_related_categories }
    WordCategory.all.each{|w| w.update_related_words }
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
  
  def related_activities
    activities = ['level_1_modeling_examples', 'level_2_modeling_examples', 'level_3_modeling_examples',
                  'activity_ideas', 'books', 'videos']
    records = linked_words
    hash = {}
    records.each do |word|
      activities.each do |act|
        if word.data && word.data[act]
          hash[act] ||= []
          hash[act] += word.data[act]
        end
      end
    end
    hash
  end
  
  WORD_TYPES = ['verbs', 'adjectives', 'adverbs', 'pronouns', 'determiners', 'time_base_words', 'location_based_words', 'other_words']
  
  STRING_PARAMS = ['description', 'verbs',
        'adjectives', 'adverbs', 'pronouns', 'determiners', 'time_based_words', 'location_based_words',
        'other_words', 'references']
  OBJ_PARAMS = ['image', 'age_range', 'level_1_modeling_examples', 'level_2_modeling_examples', 
        'level_3_modeling_examples', 'activity_ideas', 'books', 
        'videos', 'phrase_categories']
  
  def process_params(params, user_params)
    self.generate_defaults
    rev_params = {
      'revision_credit' => params['revision_credit'],
      'clear_revision_id' => params['clear_revision_id']
    }
    if user_params['user']
      rev_params['user_identifier'] = user_params['user']
      rev_params['editable'] = self.allows?(user_params['user'], 'delete')
    end
    self.process_revisions(rev_params) do |hash|
      STRING_PARAMS.each do |string_param|
        self.data[string_param] = self.process_string(params[string_param])
      end
      OBJ_PARAMS.each do |obj_param|
        self.data[obj_param] = params[obj_param]
      end
    end
    if user_params['user'] && self.allows?(user_params['user'], 'delete')
      if params['add_user_identifier']
        self.add_user_identifier(params['add_user_identifier'])
      end
    end
  end
end
