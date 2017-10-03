require 'typhoeus' 

module WordMapping
  extend ActiveSupport::Concern
  
  def process_map(params)
    # process a manually-entered map
    # images and colors are optional, this can just be a list of available core words for the user
    # this should fork the map if linked to someone else's map (with a UI warning)
    if params['external_tracking']
      self.settings['words'] = nil
      self.settings['word_map'] = nil
      self.settings['external_tracking'] = true
      self.settings['external_source_url'] = params['external_source_url'] if params['external_source_url']
      # TODO: schedule :update_map
    elsif params['linked_map_code']
      user_id, code = params['linked_map_code'].split(/:/)
      user = User.find_by_global_id(user_id)
      if user.map_code == code
        self.settings['linked_map_code'] = user.map_code
      end
    else
      if params['words']
        self.settings['words'] = params['words']
        self.settings['external_tracking'] = false
      end
      if params['word_map']
        self.settings['word_map'] = params['word_map']
        self.settings['linked_map_code'] = nil
        self.settings['external_tracking'] = false
      end
    end
  end
  
  def map_code
    code = GoSecure.sha512(self.global_id, "user word mapping")
    "#{self.global_id}:#{code[0, 20]}"
  end
  
  def update_map(remote_url=nil)
    # should be manually-updatable from the interface, or triggerable by webhook
    # (when you login as someone from CoughDrop, it should auto-subscribe to webhooks)
    if remote_url && self.settings['external_tracking']
      # server call to retrieve the latest version of the mapping
      # persist words and word_map
      res = Typhoeus.get(remote_url)
      if res.headers['Location'] && res.code >= 300 && res.code <= 399
        res = Typhoeus.get(res.headers['Location'])
      end
      json = JSON.parse(res.body) rescue nil
      puts json.to_json
      if json && json['word_map']
        tmp_words = []
        map = {}
        json['word_map'].each do |locale, locale_map|
          locale_map.each do |word, attrs|
            word = word.downcase
            tmp_words << word
            map[locale] ||= {}
            obj = {
              'label' => attrs['label'] || word,
            }
            ['border_color', 'background_color'].each do |key|
              obj[key] = attrs[key] if attrs[key]
            end
            if attrs['image'] && attrs['image']['image_url']
              obj['image'] = {}
              ['image_url', 'license', 'author', 'author_url', 'license_url', 'source_url'].each do |key|
                obj['image'][key] = attrs['image'][key] if attrs['image'][key]
              end
              obj['image_url'] = obj['image']['image_url']
            end
            map[locale][word] = obj
          end
        end
        if json['words']
          tmp_words = json['words']
        else
          tmp_words.uniq!
        end
        if tmp_words.length > 0
          self.settings['words'] = tmp_words
          self.settings['word_map'] = map
          self.save
          return true
        end
      end
      false
    end
    false
  end 
  
  def update_external_map
    # schedule an update and return a progress object
    # TODO: if for a CoughDrop account, then the URL must be custom-generated to support timing out
    url = self.settings['external_source_url']
    ua = UserAlias.find_by(:user => self, :source => 'coughdrop')
    if ua && ua.settings['access_token'] && self.settings['external_tracking']
      url = "#{ENV['COUGHDROP_HOST']}/api/v1/users/self/word_map?access_token=#{ua.settings['access_token']}"
    end
    self.update_map(url) if url
  end
  
  def word_map
    if self.settings['linked_map_code']
      user_id, code = self.settings['linked_map_code'].split(/:/)
      user = User.find_by_global_id(user_id)
      res = user && user.settings['word_map']
      if res
        res['_user_name'] = user.settings['user_name']
      end
    else
      self.settings['word_map']
    end
  end
  
  def full_map(include_supervisees=true)
    mapped_values = ['image', 'background_color', 'border_color']
    maps = [self.word_map || {}]
    locales = [self.settings['locale'] || 'en']
    res = {}
    WordData.where(:locale => locales).each do |word|
      res[word.locale] ||= {}
      entry = {
        'default' => true,
        'uses' => 0
      }
      mapped_values.each{|k| entry[k] = word.data[k] if word.data[k] }
      res[word.locale][word.word] = {
        'word' => word.word,
        'locale' => word.locale,
        'results' => [entry]
      }
    end
    maps.each do |locale_map|
      found = false
      res.each do |locale, res_word_map|
        word_map = locale_map[locale] || {}
        if res[locale]
          found = true
          res[locale].each do |word, data|
            if word_map[word]
              match = res[locale][word]['results'].detect do |r| 
                match = true
                match = false if (r['image'] || data['image']) && (r['image'] || {})['image_url'] != (data['image'] || {})['image_url']
                match = false if (r['background_color'] || data['background_color']) && r['background_color'] != data['background_color']
                match = false if (r['border_color'] || data['border_color']) && r['border_color'] != data['border_color']
                match
              end
              if match
                match['uses'] += 1
              else
                entry = {
                  'from_map' => true,
                  'uses' => 1
                }
                mapped_values.each{|k| entry[k] = word_map[word][k] if word_map[word][k]}
                res[locale][word]['results'] << entry
              end
            else
              res[locale][word]['results'][0]['uses'] += 1
            end
          end
        end
      end
    end
    res.each do |locale, word_map|
      word_map.each do |word, data|
        data['results'] = data['results'].select{|r| r['uses'] > 0 }.sort{|r| r['uses'] }.reverse if data['results'].length > 1
        data.merge!(data['results'][0])
      end
    end
    # merge the default core list with the user's word map, including
    # supervisees if specified. if multiple results, use voting to select the best result,
    # and include the alternate results as well (but not the default, if that's overriden 
    # everywhere then just drop it)
    # also include an indication of whether the word is in the map, or how many maps it's in
    res
  end
  
  module ClassMethods
    def handle_update(params)
      # find the correct user from the webhook and schedule an update
    end
  end
end