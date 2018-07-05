class Book < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Permissions
  include Async

  secure_serialize :data
  before_save :generate_defaults
  after_save :add_to_core_words
  
  add_permissions('view', ['*']) { true }
  add_permissions('edit', 'delete', ['*']) {|user| user.id == self.user_id || user.admin? }
  add_permissions('edit', 'delete', ['*']) {|user| !self.id }
  add_permissions('link') {|user| user.admin? }

  def resource_summary
    "Online accessible book: #{self.data['title'] || "Unnamed Book"}"
  end

  def resource_title
    self.data['title'] || "Unnamed Book"
  end

  def resource_author
    self.data['author'] || "Unknown Author"
  end

  def resource_link
    "#{JsonApi::Json.current_host}/books/#{ref_id}"
  end

  def resource_image
    (self.data['image'] || {})['image_url'] || ""
  end

  def json_link
    "#{JsonApi::Json.current_host}/api/v1/books/json?id=#{ref_id}"
  end

  def generate_defaults
    self.data ||= {}
    self.random_id ||= (rand(9999999999) + Time.now.to_i)
    self.locale ||= 'en'
    self.data['related_words'] = related_page_words

    true
  end
  
  def related_page_words
    tallies = {}
    self.data ||= {}
    (self.data['pages'] || []).each do |page|
      (page['related_words'] || '').split(/,|\n/).map(&:strip).each do |word|
        tallies[word] ||= 0
        tallies[word] += 1
      end
    end
    tallies.to_a.sort_by(&:last).reverse[0, 5].map(&:first)
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
    self.user_id ||= user_params['user'].id if user_params['user']
    if !params['new_core_words'].blank?
      words = params['new_core_words'].split(/,/).map(&:strip)
      self.data['target_core_words'] = ((self.data['target_core_words'] || []) + words).uniq
      self.data['new_core_words'] = words
    end
  end
  
  def full_text
    "#{self.data['title']} #{self.data['pages'].map{|p| p['text'] }.join(' ')}"
  end
  
  def add_to_core_words(frd=false)
    if self.data['new_core_words'] && !frd
      self.schedule(:add_to_core_words, true)
    elsif frd
      new_words = self.data['new_core_words']
      new_words.each do |wrd|
        word = WordData.find_by(word: wrd, locale: self.locale || 'en')
        word_book_id = "#{word.global_id}:#{self.ref_id}"
        word.data['books'] = word.data['books'].select{|b| b['id'] != word_book_id }
        word.data['books'] << {
          'url' => self.book_url,
          'book_type' => 'communication_workshop',
          'supplement' => self.full_text,
          'text' => self.data['title'],
          'image' => self.data['image'] || self.data['pages'][0]['image'],
          'local_id' => self.ref_id,
          'id' => word_book_id
        }
        word.save
      end
      self.data.delete('new_core_words')
      self.save
    end
  end
  
  def book_url
    "#{JsonApi::Json.current_host}/books/#{self.ref_id}"
  end
  
  def book_json
    book = self.data
    res = {
      'book_url' => self.book_url,
      'author' => book['author'] || 'Unknown Author',
      'title' => book['title'] || 'Unnamed Book',
      'attribution_url' => self.book_url,
      'pages' => [
        {
          'id' => 'title_page',
          'text' => book['title'] || 'Unnamed Book',
          'image_url' => (book['image'] || {})['image_url'],
          'image_content_type' => '',
          'image_attribution_type' => (book['image'] || {})['license'],
          'image_attribution_url' => (book['image'] || {})['license_url'],
          'image_attribution_author' => (book['image'] || {})['author'],
          'related_words' => self.data['related_words']
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
        'related_words' => (page['related_words'] || '').split(/,|\n/).map(&:strip)
      }
    end
    res.to_json
  end
end
