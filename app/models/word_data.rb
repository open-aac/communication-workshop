# Ideal workflow:
# people come here for some introductory training and a badge (different levels for friends, family, caregivers, therapists)
# get suggestions for what words to focus on next
# include a list of current focus words (by default they start to fade out after 2 weeks, are gone by 4 weeks)
# quick popup for suggestions on what to do around the current focus words
# quick popup for a book to read related to the current focus words
# easy assessments based on current focus words


class WordData < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Revisions
  include Permissions

  serialize :data, JSON
  before_save :generate_defaults
  after_save :update_related_categories

  add_permissions('view', ['*']) { true }
  add_permissions('revise', ['*']) {|user| !!user }
  add_permissions('edit', 'delete') {|user| user.admin? }
  
  def generate_defaults
    self.data ||= {}
    self.random_id ||= (rand(9999999999) + Time.now.to_i)
    self.enforce_ids
    self.data['related_words'] = self.possibly_related_words
    true
  end

  def update_related_categories
    return if @skip_related_update
    
    categories = (self.data['related_categories'] || '').split(/,/).map(&:strip)
    records = WordCategory.where(:locale => self.locale, :category => categories)
    records.each do |cat|
      type = (self.data['parts_of_speech'] || '').split(/,/)[0]
      type = nil unless ['verb', 'noun', 'pronoun', 'adjective', 'adverb', 'determiner', 'interjection'].include?(type)
      type = type + 's' if type
      if cat.data && type
        orig = cat.data[type]
        cat.data[type] ||= ''
        list = cat.data[type].split(/,/).map(&:strip)
        list << self.word
        cat.data[type] = list.uniq.join(', ')
        cat.instance_variable_set('@skip_related_update', true)
        cat.save if cat.data[type] != orig
        cat.instance_variable_set('@skip_related_update', false)
      end
    end
  end
  
  def find_activity(activity_id)
    parts = activity_id.split(/:/, 2)
    return nil if parts[0] != self.global_id && parts[0] != self.data['pre_id']
    OBJ_PARAMS.each do |param|
      if self.data[param] && self.data[param].is_a?(Array)
        self.data[param].each do |obj|
          if obj.is_a?(Hash)
            return obj if obj['id'] == parts[1] || obj['id'] == activity_id
          end
        end
      end
    end
    nil
  end
  
  def enforce_ids
    self.data ||= {}
    pre = self.global_id || (self.data['pre_id'] ||= "p_#{rand(999)}")
    OBJ_PARAMS.each do |param|
      if self.data[param] && self.data[param].is_a?(Array)
        self.data[param].each_with_index do |obj, idx|
          if obj.is_a?(Hash)
            obj['id'] ||= "#{pre}:#{idx}_#{rand(999)}_#{Time.now.to_i}"
            if !obj['id'].match(/:/)
              obj['id'] = pre + ":" + obj['id']
            end
          end
        end
      end
      (self.data['revisions'] || []).each do |rev|
        if rev['changes'][param] && rev['changes'][param].is_a?(Array)
          rev['changes'][param].each_with_index do |obj, idx|
            if obj.is_a?(Hash)
              obj['id'] ||= "#{pre}:r#{idx}_#{rand(999)}_#{Time.now.to_i}"
              if !obj['id'].match(/:/)
                obj['id'] = pre + ":" + obj['id']
              end
            end
          end
        end
      end
    end
  end
  
  def display_id
    "#{self.word}:#{self.locale}"
  end
  
  def self.suggestions_for(user, include_linked_users=false, word_id=nil)
    # TODO: bump if at the user's modeling level
    # TODO: major unbump if already used or downvoted/dismissed
    # TODO: add jitter so it's not always the same order every time
    # TODO: weighting function for past words, words that are fading out
    res = {
      'modeling' => [],
      'activities' => [],
      'prompts' => []
    }
    refs = user.current_words(!!include_linked_users)
    focus_words = refs.map{|r| r['word'] }
    strict_re = focus_words.length > 0 ? Regexp.new(focus_words.map{|w| "\\b#{w}\\b" }.join('|'), 'i') : /$^/
    loose_re = focus_words.length > 0 ? Regexp.new(focus_words.map{|w| "\\b#{w}" }.join('|'), 'i') : /$^/
    # TODO: define starred_ids
    starred_ids = {}
    (user.settings['starred_activity_ids'] || []).each{|id| starred_ids[id] = true }
    # TODO: define finished_ids
    finished_ids = {}
    all_ids = refs.map{|r| r['internal_id'] }
    histories = {}
    now = Time.now.to_i
    year_ago = 1.year.ago.to_i
    past_words = []
    user.past_words.each do |word|
      all_ids << word['internal_id']
      stamp = Time.parse(word['added']).to_i
      histories[word['internal_id']] = [0, stamp - year_ago].max.to_f / (now - year_ago).to_f
      past_words << word['word']
    end
    strict_past = past_words.length > 0 ? Regexp.new(past_words.map{|w| "\\b#{w}\\b" }.join('|'), 'i') : /$^/
    loose_past = past_words.length > 0 ? Regexp.new(past_words.map{|w| "\\b#{w}" }.join('|'), 'i') : /$^/
    words = WordData.find_all_by_global_id(all_ids)
    all_words = []
    if word_id
      word = WordData.find_by_path(word_id)
      all_words << [word, 1.0] if word
    else
      words.each{|word| all_words << [word, histories[word.global_id] || 1.0] }
    end
    all_words.each do |word, history_distance|
      [1,2,3].each do |level|
        (word.data["level_#{level}_modeling_examples"] || []).each do |ex|
          score = 1
          ex_id = ex['id']
          ex_id = "#{word.global_id}:#{ex['id']}" if ex_id && !ex['id'].match(/:/)
          parts = ex['sentence'].downcase.split(/\s/)
          matches = parts & focus_words
          score += matches.length
          if ex['text']
            score += ex['text'].scan(strict_re).length.to_f / 3.0
            score += ex['text'].scan(loose_re).length.to_f / 10.0
            score += ex['text'].scan(strict_past).length.to_f / 6.0
            score += ex['text'].scan(loose_past).length.to_f / 10.0
          end
          score *= 2 if starred_ids[ex['id']]
          score *= history_distance
          res['modeling'] << {
            'id' => ex_id,
            'word' => word.word,
            'locale' => word.locale,
            'level' => level,
            'data' => ex.merge({'id' => ex_id}),
            'history_distance' => history_distance,
            'match_score' => score.round(3),
            'jittered_match_score' => (score.round(3) + (rand - 0.5))
          } unless finished_ids[ex['id']]
        end
      end
      ['learning_projects', 'activity_ideas', 'books', 'topic_starts', 'videos', 'send_homes'].each do |activity|
        (word.data[activity] || []).each do |ex|
          score = 1
          ex_id = ex['id']
          ex_id = "#{word.global_id}:#{ex['id']}" if ex_id && !ex['id'].match(/:/)
          if ex['related_words']
            parts = ex['related_words'].split(/[,\s]/)
            matches = parts & focus_words
            score += matches.length
          end
          if ex['supplement']
            score += ex['supplement'].scan(strict_re).length.to_f / 6.0
            score += ex['supplement'].scan(loose_re).length.to_f / 20.0
            score += ex['supplement'].scan(strict_past).length.to_f / 9.0
            score += ex['supplement'].scan(loose_past).length.to_f / 30.0
          end
#          raise ex.to_json if ex['id'] == '0_38_1502394250'
          score += ex['text'].scan(strict_re).length.to_f / 3.0
          score += ex['text'].scan(loose_re).length.to_f / 10.0
          score += ex['text'].scan(strict_past).length.to_f / 6.0
          score += ex['text'].scan(loose_past).length.to_f / 10.0
          score *= 2 if starred_ids[ex['id']]
          score *= history_distance
          res['activities'] << {
            'id' => ex_id,
            'word' => word.word,
            'locale' => word.locale,
            'type' => activity,
            'data' => ex.merge({'id' => ex_id}),
            'history_distance' => history_distance,
            'match_score' => score.round(3),
            'jittered_match_score' => (score.round(3) + (rand - 0.5))
          } unless finished_ids[ex['id']]
        end
      end
      (word.data['prompts'] || []).each do |ex|
        ex_id = ex['id']
        ex_id = "#{word.global_id}:#{ex['id']}" if ex_id && !ex['id'].match(/:/)
        score = 1
        score += ex['text'].scan(strict_re).length.to_f / 3.0
        score += ex['text'].scan(loose_re).length.to_f / 10.0
        score += ex['text'].scan(strict_past).length.to_f / 6.0
        score += ex['text'].scan(loose_past).length.to_f / 20.0
        score *= 2 if starred_ids[ex['id']]
        score *= history_distance
        res['prompts'] << {
          'id' => ex_id,
          'word' => word.word,
          'locale' => word.locale,
          'data' => ex.merge({'id' => ex_id}),
          'history_distance' => history_distance,
          'match_score' => score.round(3),
          'jittered_match_score' => (score.round(3) + (rand - 0.5))
        } unless finished_ids[ex['id']]
      end
    end
    res['modeling'] = res['modeling'].shuffle.sort_by{|m| m['jittered_match_score'] }.reverse
    res['activities'] = res['activities'].shuffle.sort_by{|m| m['jittered_match_score'] }.reverse
    res['prompts'] = res['prompts'].shuffle.sort_by{|m| m['jittered_match_score'] }.reverse
    res
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
  
  def linked_words
    all = (self.data['related_words'] || self.possibly_related_words).map(&:downcase)
    tallies = {}
    all.each do |word|
      tallies[word] = (tallies[word] || 0) + 1
    end
    tallies
  end
  
  def possibly_related_words
    res = []
    CORE_WORD_PARAMS.each do |key|
      words = self.data[key]
      res += words.split(/,/) if words && words.length > 0
      res += words.split(/,/) if words && words.length > 0
    end
    [1,2,3].each do |level|
      (self.data["level_#{level}_modeling_examples"] || []).each do |ex|
        res += ex['sentence'].downcase.split(/\s/) if ex['sentence']
        res += ex['text'].downcase.split(/\s/) if ex['text']
      end
    end
    ['learning_projects', 'activity_ideas', 'books', 'topic_starts', 'videos', 'send_homes'].each do |activity|
      (self.data[activity] || []).each do |ex|
        res += ex['related_words'].split(/[,\s]/) if ex['related_words']
        res += ex['supplement'].split(/\s/) if ex['supplement']
        res += ex['text'].split(/\s/) if ex['text']
      end
    end
    (self.data['prompts'] || []).each do |ex|
      res += ex['text'].split(/\s/) if ex['text']
    end
    res
  end

  CORE_WORD_PARAMS = ['verbs', 'adjectives', 'adverbs', 'pronouns', 'determiners', 'time_based_words', 'location_based_words', 'other_words']

  STRING_PARAMS = ['border_color', 'background_color', 'description', 'parts_of_speech', 'verbs',
        'adjectives', 'adverbs', 'pronouns', 'determiners', 'time_based_words', 'location_based_words',
        'other_words', 'related_categories', 'references']
  OBJ_PARAMS = ['image', 'usage_examples', 'level_1_modeling_examples', 'level_2_modeling_examples', 
        'level_3_modeling_examples', 'prompts', 'learning_projects', 'activity_ideas', 'books', 
        'topic_starters', 'videos', 'send_homes']
  
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
        hash[string_param] = self.process_string(params[string_param])
      end
      ['border_color', 'background_color'].each do |key|
        hash[key] = self.process_color(params[key]) if params[key] && params[key].length > 0
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
  
  # based on survey results, https://docs.google.com/spreadsheets/d/1VU_PXdl4zmEAmgFKp5O5GdlA0c8NOekoCCogOtO42W4/edit#gid=962667888
  EN_ORDERED_WORDS = ["go", "want", "more", "stop", "like", "help", "turn", "i", "play", "you", "not", "eat", "in", "look", "do", "no", "get", "that", "it", "put", "open", "on", "yes", "all done", "out", "finished", "drink", "different", "what", "off", "make", "up", "me", "done", "hi", "have", "who", "where", "read", "mine", "down", "all", "need", "feel", "don’t", "bye", "big", "this", "slow", "see", "same", "my", "happy", "fast", "come", "close", "again", "wait", "they", "little", "listen", "your", "went", "watch", "walk", "tell", "show", "she", "question", "move", "mad", "he", "good", "give", "finish", "don’t like", "can", "bring", "break", "work", "some", "here"]
end
