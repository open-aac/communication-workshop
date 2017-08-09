require 'sanitize'

module Revisions
  extend ActiveSupport::Concern
  
  def process_revisions(user_params, &block)
    if user_params['editable']
      block.call(self.data)
    elsif user_params['user_identifier']
      rev = JSON.parse(self.data.to_json)
      block.call(rev)
      changes = {}
      rev.each do |key, val|
        if val.is_a?(Array)
          objs = self.data[key].map(&:to_json)
          val.each do |v|
            if !objs.include?(v.to_json)
              changes[key] ||= []
              changes[key] << v
            end
          end
        elsif val.to_json != self.data[key].to_json
          changes[key] = val
        end
      end
      if changes.keys.length > 0
        self.data['revisions'] ||= []
        self.data['revisions'] << {'user_identifier' => user_params['user_identifier'], 'changes' => changes}
        self.pending_since ||= Time.now
      end
    else
      raise "missing revision parameters"
    end
    if user_params['user_identifier']
      self.data['all_user_identifiers'] ||= []
      self.data['all_user_identifiers'] << user_params['user_identifier']
      self.data['all_user_identifiers'].uniq!
    end
    true
  end
  
  def add_user_identifier(user_identifier)
    self.data['approved_user_identifiers'] ||= []
    self.data['approved_user_identifiers'] << user_identifier
    self.data['approved_user_identifiers'].uniq!
  end
  
  def pending_user_identifiers
    self.data['revisions'].map{|r| r['user_identifier'] }.uniq
  end
  
  def approve_revisions(user_identifier)
    self.data['revisions'] ||= []
    new_revs = []
    found = false
    self.data['revisions'].each do |rev|
      if rev['user_identifier'] == user_identifier && !found
        changes.each do |key, val|
          if val.is_a?(Array)
            self.data[key] ||= []
            val.each do |v|
              self.data[key] << v
            end
          else
            self.data[key] = val
          end
        end
      else
        new_revs << rev
      end
    end
    self.data['revisions'] = new_revs
    self.data['approved_user_identifiers'] ||= []
    self.data['approved_user_identifiers'] << user_identifier
    self.data['approved_user_identifiers'].uniq!
    self.pending_since = nil if self.data['revisions'].length == 0
    self.save
  end
end