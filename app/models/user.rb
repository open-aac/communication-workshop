class User < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Permissions
  include WordMapping

  add_permissions('view', ['*']) {|user| user == self }
  add_permissions('edit', 'delete') {|user| user == self || user.admin? }

  secure_serialize :settings
  before_save :generate_defaults
  after_destroy :destroy_data
  
  def generate_defaults
    self.settings ||= {}
    self.hashed_email = self.class.email_hash(self.settings['email']) if self.settings['email']
    self.hashed_identifier = self.class.user_name_hash(self.settings['user_name']) if self.settings['user_name']
    true
  end
  
  def admin?
    !!self.settings['admin']
  end
  
  def destroy_data
    UserData.where(user_id: self.id).destroy_all
  end

  def generate_password(str)
    self.settings ||= {}
    self.settings['password'] = GoSecure.generate_password(str)
  end

  def permission_scopes
    ['full']
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
  
  def password_reset_token
    clean_password_reset_tokens
    token = "#{Time.now.to_i}-#{GoSecure.nonce('password_reset_token')}"
    self.settings['password_reset_tokens'] << token
    self.save
    token
  end
  
  def clean_password_reset_tokens
    self.settings['password_reset_tokens'] ||= []
    self.settings['password_reset_tokens'].select do |token|
      ts, extra = token.split('-')
      ts = ts.to_i
      return ts > 3.weeks.ago.to_i
    end
  end
  
  def update_password(token, password)
    clean_password_reset_tokens
    if self.settings['password_reset_tokens'].include?(token)
      self.settings['password_reset_tokens'] -= [token]
      self.generate_password(password)
      self.save
    else
      false
    end
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
    ref_id = activity['id']
    if !ref_id.match(/^#{word.global_id}/)
      ref_id = "#{word.global_id}:#{activity['id']}"
    end
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

  def skip_activity(word, activity)
    WordLink.find_or_create_by(:word_id => word.id, :link_id => self.id, :link_type => 'User', :link_purpose => 'skip')
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
    self.class.recommended_words(self, include_linked_users)
  end
  
  def self.recommended_words(user=nil, include_linked_users=true)
    extra_weights = {}
    WordData::EN_ORDERED_WORDS.each_with_index{|wrd, idx| extra_weights[wrd] = (WordData::EN_ORDERED_WORDS.length - idx).to_f / (WordData::EN_ORDERED_WORDS.length) * 5.0 }
    current_hash = {}
    res = []
    available_hash = {}

    if user
      current = user.current_words
      (user.settings['words'] || []).each{|w| available_hash[w] = true }
      current.each{|w| current_hash[w['word']] = true }
      past = user.past_words
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
    
      link_weights.each do |locale, weights|
        matches = WordData.where(:has_content => true, :locale => locale, :word => weights.to_a.map(&:first))
        map = {}
        matches.each{|w| map[w.word] = w }
        weights.to_a.each do |str, weight|
          res << [map[str], weight] if map[str] && !current_hash[str]
        end
      end
    end

    if res.length < 25
      ptr = WordData.count
      # fall back to whatever words are in their word settings
      if user
        WordData.where(:has_content => true, :word => user.settings['words']).order('word').each do |word|
          res << [word, 1.0] unless current_hash[word.word]
        end
      end
      if res.length < 25
        WordData.where(:has_content => true, :word => WordData::EN_ORDERED_WORDS).each do |word|
          res << [word, 1.0] unless current_hash[word.word]
        end
      end
      # fall back even more to any words at all
      if res.length < 25
        WordData.where(:has_content => true).order('random_id').limit(50).offset(rand(ptr / 4)).each do |word|
          if res.length < 25
            res << [word, 1.0] unless current_hash[word.word]
          end
        end
      end
    end
    res.each do |arr|
      if extra_weights[arr[0].word]
        arr[1] += extra_weights[arr[0].word] 
      end
    end
    res = res.sort_by{|word, weight| [-1 * weight, word.word] }.map(&:first).uniq

    list = []
    res.each_with_index{|w, idx| list << [w, idx] }
    res = list.sort_by{|w, idx| [user && available_hash[w.word] ? 0 : 1, idx] }.map(&:first)
    res.select{|w| w.has_baseline_content }
  end

  def related_categories(include_linked_users=true)
    current = self.current_words
    current_hash = {}
    available_hash = {}
    (self.settings['words'] || []).each{|w| available_hash[w] = true }
    current.each{|w| current_hash[w['word']] = true }
    past = self.past_words
    link_weights = {}
    valid = WordData.find_all_by_global_id(current.map{|w| w['internal_id'] } + past.map{|w| w['internal_id'] })
    valid.each do |word|
      cats = (word.data['related_categories'] || '').split(/,/).map(&:strip)
      link_weights[word.locale]
      cats.each do |link|
        link_weights[word.locale] ||= {}
        link_weights[word.locale][link] ||= 0
        link_weights[word.locale][link] += 1
        link_weights[word.locale][link] += 1 if current_hash[word.word]
        if available_hash[word.word]
          link_weights[word.locale][link] += 5
        end
      end
    end
    res = []
    link_weights.each do |locale, weights|
      matches = WordCategory.where(:has_content => true, :locale => locale, :category => weights.to_a.map(&:first))
      map = {}
      matches.each{|w| map[w.category] = w }
      weights.to_a.sort_by(&:last).reverse.map(&:first).each do |str|
        res << map[str] if map[str] && !current_hash[str]
      end
    end
    if res.length < 25
      ptr = WordCategory.count
      WordCategory.where(:has_content => true).order('random_id').limit(50).offset(rand(ptr / 4)).each do |cat|
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
  
  def track_activity(word, activity_id, details)
    details ||= {}
    time = Time.parse("#{details['date'] || ''}T#{details['time'] | ''}") rescue nil
    activity = word.find_activity(activity_id)
    return false unless activity
    
    cutoff = 12.hours.ago.iso8601
    
    data = UserData.find_or_create_by(:user_id => self.id)
    data.data ||= {}
    data.data['activities'] ||= []
    match = data.data['activities'].detect{|a| a['id'] == activity_id && a['tracked'] > cutoff }
    
    res = {
      'unique_id' => "#{activity_id}:#{Time.now.to_i}",
      'id' => activity_id,
      'activity_id' => activity_id,
      'text' => activity['text'],
    }
    ['success_level', 'notes'].each{|k| res[k] = details[k] if details[k] }
    if time || !match || !match['tracked']
      time ||= Time.now
      iso = time.utc.iso8601
      res = res.merge({
        'tracked' => iso,
        'date' => iso[0, 10],
        'time' => iso[11, 5],
      })
    end
    # if this activity has already been tracked recently, override the last instance
    if match
      if details['remove']
        data.data['activities'] -= [match]
        WordLink.where(:word_id => word.id, :link_id => self.id, :link_type => 'User', :link_purpose => 'completion').destroy_all
      else
        match.merge!(res)
        res.merge!(match)
        res['updated'] = true
        WordLink.find_or_create_by(:word_id => word.id, :link_id => self.id, :link_type => 'User', :link_purpose => 'completion')
      end
    else
      data.data['activities'] << res
    end
    # TODO: connect the word and the user via WordLink as a usage link
    data.save
    res
  end
  
  def recent_activities(include_supervisees=true)
    users = [self]
    datas = UserData.where(:user_id => users.map(&:id))
    res = []
    cutoff = 2.weeks.ago.iso8601
    user_names = {}
    users.each{|u| user_names[u.id] = u.settings['user_name'] }
    datas.each do |data|
      data.data['activities'].each do |activity|
        if activity['tracked'] > cutoff
          res << {'unique_id' => "#{activity['activity_id']}:#{activity['tracked']}"}.merge(activity).merge({'user_id' => data.related_global_id(data.user_id), 'user_name' => user_names[data.user_id]})
        end
      end
    end
    res.sort_by{|a| a['tracked'] }.reverse
  end
  
  def self.user_name_hash(str)
    GoSecure.sha512(str, 'hashed_user_name')
  end
    
  def self.email_hash(str)
    GoSecure.sha512(str.downcase, 'hashed_email')
  end

  def process_params(params, user_params)
    self.settings ||= {}
    if !self.id && params['user_name']
      if !params['user_name'].match(/^[\w_-]+$/) || params['user_name'].length < 3
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
    if !self.id
      self.settings['password'] ||= self.generate_password(params['password'] || rand(99999999).to_s)
    end
    if !params['password'].blank? && !params['old_password'].blank?
      if self.valid_password?(params['old_password'])
        self.generate_password(params['password'])
      else
        self.add_processing_error('password mismatch')
      end
    end
    # TODO: alert new and old email address when changed
    self.settings['terms_agree'] = params['terms_agree'] if params['terms_agree']
    self.settings['email'] = params['email'] if params['email']
    self.settings['name'] = params['name'] if params['name']
    self.settings['modeling_level'] = params['modeling_level'] if params['modeling_level']
    self.settings['focus_length'] = params['focus_length'] if params['focus_length']
    self.process_map(params)
    true
  end

  def generate_token!
    ua = UserAuth.find_or_create_by(:user => self)
    ua.generate_token!
  end
  
  def self.assert_user!(opts)
    ua = UserAlias.find_or_create_by(:identifier => opts[:remote_user_name], :source => opts[:source])
    ua.settings[:access_token] = opts[:access_token]
    ua.settings[:metadata] = opts[:metadata]
    anon = nil
    if opts[:remote_anonymized_user_id]
     anon = UserAlias.find_or_create_by(:identifier => opts[:remote_anonymized_user_id], :source => "#{opts[:source]}-anon")
     opts[:current_user] ||= anon.user
    end
    user = ua.user
    if !ua.user
      if opts[:current_user]
        user = opts[:current_user]
        user.settings['email'] ||= opts[:email]
        user.settings['name'] ||= opts[:remote_name]
        user.settings['external_tracking'] = true
        user.settings['external_account'] = opts[:source]
        user.settings['remote_anonymized_user_id'] = opts[:remote_anonymized_user_id]
      else
        user = User.new
        user.settings = {
          user_name: "#{opts[:source]}::#{opts[:remote_user_name]}",
          remote_anonymized_user_id: opts[:remote_anonymized_user_id],
          email: opts[:email],
          name: opts[:remote_name],
          external_tracking: true,
          external_account: opts[:source]
        }
      end
      user.save!
    end
    ua.user = user
    ua.save
    if opts[:remote_anonymized_user_id]
      if anon.user && anon.user != user && anon.user.placeholder?
        user.settings['starred_activity_ids'] ||= []
        user.settings['starred_activity_ids'] = ((user.settings['starred_activity_ids'] || []) + (anon.user.settings['starred_activity_ids'] || [])).uniq 
        anon_data = UserData.find_by(:user_id => anon.user.id)
        if anon_data
          user_data = UserData.find_or_create_by(:user_id => user.id)
          user_data.data['activities'] ||= []
          user_data.data['activities'] += anon_data.data['activities']
          user_data.data['actviities'].sort_by!{|a| a['tracked'] || '' }
        end
        anon.user
        anon.user.destroy

        # TODO: transfer extra info from the old user to the new user
        # and delete the old user if it was a placeholder user
      end
      anon.user = user
      anon.save
    end
    user
  end

  def placeholder?
    !self.settings['user_name']
  end

  def self.process_external_activities(anonymized_user_id, source, updates)
    ua = UserAlias.find_or_create_by(identifier: anonymized_user_id, source: source)
    user = ua && ua.user
    return false unless user && updates && updates.length > 0
    updates.each do |update|
      word = WordData.find_by(word: update['word'], locale: update['locale'])
      activity = word.find_activity(update['activity_id'])

      if word && activity
        # If no user defined, make a placeholder one with no private info
        if !user
          user = User.new
          user.settings = {
            remote_anonymized_user_id: opts[:remote_anonymized_user_id],
            external_tracking: true,
            external_account: opts[:source]
          }
          user.save
          ua.user = user
          ua.save
        end

        if update['activity'] == 'dismiss'
          user.skip_activity(word, activity)
        elsif update['activity'] == 'attempt'
          user.star_activity(word, activity, :star)
        elsif update['activity'] == 'complete'
          user.track_activity(word, activity, {
            'success_level' => update['score']
          })
        end
      end
    end
    true
  end
  
  def usage_stats
  end
end
