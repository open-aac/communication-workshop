class UserImage < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Permissions
  include Async
  protect_global_id
  secure_serialize :settings
  before_save :generate_defaults
  after_save :schedule_processing

  add_permissions('view', ['*']) { true }
  add_permissions('edit', 'delete', ['*']) {|user| user.id == self.user_id || user.admin? }
  add_permissions('edit', 'delete', ['*']) {|user| !self.id }

  def generate_defaults
    self.settings ||= {}
  end
  
  def redirect_url
    self.settings['processed_url'] || self.settings['entry_url']
  end
  
  def data_uri_parts
    url = self.settings['entry_url']
    return nil unless url.match(/^data:/)
    data_uri = url #"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=="
    data_uri = data_uri.sub(/^data:/, '')
    content_type, post = data_uri.split(/;/)
    content = post.sub(/^base64,/, '')
    {
      :binary => Base64.decode64(content),
      :type => content_type
    }
  end
  
  def schedule_processing(force=false)
    if !self.settings['processed_url'] || force
      if !self.settings['process_attempts'] || self.settings['process_attempts'] < 5
        if !self.settings['processing_start'] || self.settings['processing_start'] < 24.hours.ago.iso8601
          self.schedule(:process_image)
        end
      end
    end
    true
  end
  
  def process_image
    return if self.settings['processed_url']
    return if self.settings['processing_start'] && self.settings['processing_start'] > 6.hours.ago.iso8601
    self.settings['process_attempts'] = (self.settings['process_attempts'] || 0) + 1
    self.settings['processing_start'] = Time.now.iso8601
    self.save
    # download the image
    return unless self.settings['entry_url']
    res = Typhoeus.get(self.settings['entry_url'], followlocation: true)
    if res.code >= 300
      self.settings['processing_start'] = nil
      self.save
      return
    end
    content_type = res.headers['Content-Type']
    file = Tempfile.new(["image_stash", 'pic'])
    file.binmode
    file.write res.body
    file.close
    # upload it to storage system
    id_in_parts = self.id.to_s.scan(/./).join('/')
    url = Uploader.remote_upload("workshop/images/#{id_in_parts}/#{self.global_id}", file.path, content_type)
    # set the processed_url
    self.settings['processed_url'] = url
    # unset the processing_start flag
    self.settings['processing_start'] = nil
    self.save
  end
  
  def self.migrate_image(url)
    # http://localhost:4321/api/v1/images/pixabay/bb4832c89a2c4e425e
    if url && url.match(/\/api\/v1\/images\/pixabay/)
      id = url.match(/\/api\/v1\/images\/pixabay\/(\w+)/)[1]
      key = ENV['PIXABAY_KEY']
      res = Typhoeus.get("https://pixabay.com/api/?key=#{key}&id=#{id}&response_group=high_resolution")
      json = JSON.parse(res.body) rescue nil
      if !json
        return url
      end
      temp_url = json['hits'][0]['largeImageURL']
      image = UserImage.new
      image.settings = {}
      image.settings['entry_url'] = temp_url
      image.process_image
      return image.settings['processed_url'] || url
    else
      url      
    end
  end
  
  def self.migrate_json(obj)
    json = obj.to_json
    while json.match(/https?:\/\/[^\/]+\/api\/v1\/images\/pixabay\/\w+/)
      url = json.match(/https?:\/\/[^\/]+\/api\/v1\/images\/pixabay\/\w+/)[0]
      new_url = migrate_image(url)
      json = json.sub(url, new_url)
    end
    JSON.parse(json)
  end

  
  def process_params(params, user_params)
    raise "user required" unless user_params[:user]
    self.user_id ||= user_params[:user].id
    self.settings ||= {}
    self.settings['entry_url'] = params['url'] if params['url']
  end
end
