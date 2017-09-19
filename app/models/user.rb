class User < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Permissions

  add_permissions('view', ['*']) {|user| user == self }
  add_permissions('edit', 'delete') {|user| user == self || user.admin? }

  secure_serialize :settings
  before_save :generate_defaults
  
  def generate_defaults
    self.settings ||= {}
    self.hashed_email = self.class.email_hash(self.settings['email']) if self.settings['email']
    self.hashed_identifier = self.class.user_name_hash(self.settings['user_name']) if self.settings['user_name']
    true
  end
  
  def admin?
    !!self.settings['admin']
  end
  
  def generate_password(str)
    self.settings ||= {}
    self.settings['password'] = GoSecure.generate_password(str)
  end

  def permission_scopes
    []
  end
  
  def valid_password?(str)
    GoSecure.matches_password?(str, self.settings['password'])
  end
  
  def self.find_for_login(login)
    res = self.find_by_path(login)
    res ||= self.find_by_path(login.downcase)
    if !res && login.match(/@/)
      us = User.find_by(:hashed_email => self.email_hash(login))
      res = us[0] if us.length == 1
    end
    res
  end
  
  def add_word(word, params)
    append = params['append']
    users = params['users']
    self.conclude_words(!append)
    self.settings['prior_words'] = self.settings['prior_words'].select{|w| w['internal_id'] != word.global_id }
    self.settings['current_words'] << {
      id: word.display_id,
      internal_id: word.global_id,
      word: word.word,
      locale: word.locale,
      added: Time.now.iso8601,
      concludes: words_expire.from_now.iso8601
    }
    self.settings['prior_words'] = self.settings['prior_words'].reverse.uniq{|w| w['internal_id'] }.reverse
    self.settings['current_words'] = self.settings['current_words'].reverse.uniq{|w| w['internal_id'] }.reverse
    self.save
    [self.settings['user_name']]
  end
  
  def conclude_words(conclude_all=false)
    now = Time.now.iso8601
    self.settings['prior_words'] ||= []
    self.settings['current_words'] ||= []
    oldies = self.settings['current_words'].select{|w| w['concludes'] && w['concludes'] < now }
    if conclude_all
      oldies = self.settings['current_words']
      self.settings['current_words'] = []
    end
    oldies.each do |w|
      self.settings['prior_words'] << {
        id: w['id'],
        internal_id: w['internal_id'],
        locale: w['locale'],
        word: w['word'],
        auto_concluded: !!(!conclude_all && w['concludes']),
        concluded: w['concludes'] || now
      }
    end
  end
  
  def words_expire
    4.weeks
  end

  def remove_word(word, params)
    users = params['users']
    self.conclude_words
    added = self.settings['current_words'].detect{|w| w['internal_id'] == word.global_id }
    if added && added['added'] && added['added'] < 24.hours.ago.iso8601
      self.settings['prior_words'] << {
        id: word.display_id,
        internal_id: word.global_id,
        word: word.word,
        locale: word.locale,
        concluded: Time.now.iso8601
      }
    end
    self.settings['current_words'] = self.settings['current_words'].select{|w| w['internal_id'] != word.global_id }
    self.settings['prior_words'] = self.settings['prior_words'].reverse.uniq{|w| w['internal_id'] }.reverse
    self.settings['current_words'] = self.settings['current_words'].reverse.uniq{|w| w['internal_id'] }.reverse
    self.save
    [self.settings['user_name']]
  end
  
  def star_activity(word, activity, action)
    ref_id = "#{word.global_id}:#{activity['id']}"
    self.settings['starred_activity_ids'] = (self.settings['starred_activity_ids'] || []).select{|id| id != ref_id }
    if action == :star
      self.settings['starred_activity_ids'] << ref_id
      WordLink.find_or_create_by(:word_id => word.id, :link_id => self.id, :link_type => 'User', :link_purpose => 'stars')
    else
      if !self.settings['starred_activity_ids'].detect{|id| id.match(/^#{word.global_id}/) }
        WordLink.where(:word_id => word.id, :link_id => self.id, :link_type => 'User', :link_purpose => 'stars').destroy_all
      end
    end
    self.save
    # TODO: some way to link users to words/activities so that it's easier to count
    # the stars for each activity
    {:success => true, :starred => action == :star}
  end

  def current_words(include_linked_users=true)
    words = {}
    now = Time.now.iso8601
    (self.settings['current_words'] || []).each do |word|
      if !word['concludes'] || word['concludes'] > now
        words[word['id']] ||= {
          'id' => word['id'],
          'internal_id' => word['internal_id'],
          'word' => word['word'],
          'locale' => word['locale'],
          'concludes' => word['concludes'],
          'users' => []
        }
        # TODO: figure out concludes with multiple users
        words[word['id']]['users'] << self.settings['user_name']
      end
    end
    res = []
    words.each do |id, word|
      res << word
    end
    res
  end
  
  def prior_words(include_linked_users=true)
    words = {}
    now = Time.now.iso8601
    (self.settings['prior_words'] || []).each do |word|
      words[word['id']] ||= {
        'id' => word['id'],
        'internal_id' => word['internal_id'],
        'word' => word['word'],
        'locale' => word['locale'],
        'concluded' => word['concluded'],
        'users' => []
      }
      words[word['id']]['concluded'] = [word['concluded'], words[word['id']['concluded']]].max
      words[word['id']]['users'] << self.settings['user_name']
    end
    (self.settings['current_words'] || []).each do |word|
      if word['concludes'] || word['concludes'] < now
        words[word['id']] ||= {
          'id' => word['id'],
          'internal_id' => word['internal_id'],
          'word' => word['word'],
          'locale' => word['locale'],
          'concluded' => word['concludes'],
          'users' => []
        }
        words[word['id']]['concluded'] = [word['concluded'], words[word['id']['concluded']]].max
        words[word['id']]['users'] << self.settings['user_name']
      end
    end
    res = []
    words.each do |id, word|
      res << word
    end
    res
    
  end
  
  def related_words(include_linked_users=true)
    current = self.current_words
    current_hash = {}
    current.each{|w| current_hash[w['word']] = true }
    past = self.past_words
    link_weights = {}
    valid = WordData.find_all_by_global_id(current.map{|w| w['internal_id'] } + past.map{|w| w['internal_id'] })
    valid.each do |word|
      word.linked_words.each do |link, tally|
        link_weights[word.locale] ||= {}
        link_weights[word.locale][link] ||= 0
        link_weights[word.locale][link] += tally
        link_weights[word.locale][link] += tally if current_hash[link]
      end
    end
    res = []
    link_weights.each do |locale, weights|
      matches = WordData.where(:locale => locale, :word => weights.to_a.map(&:first))
      map = {}
      matches.each{|w| map[w.word] = w }
      weights.to_a.sort_by(&:last).reverse.map(&:first).each do |str|
        res << map[str] if map[str] && !current_hash[str]
      end
    end
    if res.length < 25
      WordData.all.order('random_id').limit(50).each do |word|
        if res.length < 25
          res << word unless res.include?(word) || current_hash[word.word]
        end
      end
    end
    res
  end

  def related_categories(include_linked_users=true)
    current = self.current_words
    current_hash = {}
    current.each{|w| current_hash[w['word']] = true }
    past = self.past_words
    link_weights = {}
    valid = WordData.find_all_by_global_id(current.map{|w| w['internal_id'] } + past.map{|w| w['internal_id'] })
    valid.each do |word|
      cats = (word.data['related_categories'] || '').split(/,/)
      link_weights[word.locale]
      cats.each do |link, tally|
        link_weights[word.locale] ||= {}
        link_weights[word.locale][link] ||= 0
        link_weights[word.locale][link] += 1
        link_weights[word.locale][link] += 1 if current_hash[word.word]
      end
    end
    res = []
    link_weights.each do |locale, weights|
      matches = WordCategory.where(:locale => locale, :category => weights.to_a.map(&:first))
      map = {}
      matches.each{|w| map[w.category] = w }
      weights.to_a.sort_by(&:last).reverse.map(&:first).each do |str|
        res << map[str] if map[str] && !current_hash[str]
      end
    end
    if res.length < 25
      WordCategory.all.order('random_id').limit(50).each do |cat|
        if res.length < 25
          res << cat unless res.include?(cat)
        end
      end
    end
    res
  end
  
  def past_words(include_linked_users=true)
    words = {}
    (self.settings['past_words'] || []).each do |word|
      words[word['id']] ||= {
        'id' => word['id'],
        'internal_id' => word['internal_id'],
        'word' => word['word'],
        'locale' => word['locale'],
        'users' => [],
        'added' => word['added']
      }
      words[word['id']]['users'] << self.settings['user_name']
      words[word['id']]['added'] = [words[word['id']]['added'], word['added']].max
    end
    res = []
    words.each do |id, word|
      res << word
    end
    res
  end

  
  def self.user_name_hash(str)
    GoSecure.sha512(str, 'hashed_user_name')
  end
  
  def self.email_hash(str)
    GoSecure.sha512(str.downcase, 'hashed_email')
  end

  def process_params(params, user_params)
    if !self.id && params['user_name']
      if !params['user_name'].match(/^[\w_-]+$/)
        add_processing_error("invalid user name")
        return false
      end
      u = User.find_by(:hashed_identifier => self.class.user_name_hash(params['user_name']))
      if u
        add_processing_error("user name is taken")
        return false
      end
      self.settings['user_name'] = params['user_name']
    end
    # TODO: alert new and old email address when changed
    self.settings['email'] = params['email']
  end

  def generate_token!
    ua = UserAuth.find_or_create_by(:user => self)
    ua.generate_token!
  end
  
  def self.assert_user!(opts)
    ua = UserAlias.find_or_create_by(:identifier => opts[:remote_user_name], :source => opts[:source])
    ua.settings[:access_token] = opts[:access_token]
    ua.settings[:metadata] = opts[:metadata]
    user = ua.user
    if !ua.user
      if opts[:current_user]
        user = opts[:current_user]
        user.settings['email'] ||= opts[:email]
        user.settings['name'] ||= opts[:remote_name]
      else
        user = User.new
        user.settings = {
          user_name: "#{opts[:source]}::#{opts[:remote_user_name]}",
          email: opts[:email],
          name: opts[:remote_name]
        }
      end
      user.save!
    end
    ua.user = user
    ua.save
    user
  end
  
  def usage_stats
  end
end
