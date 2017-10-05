require 'sanitize'

module Revisions
  extend ActiveSupport::Concern
  
  def process_revisions(user_params, &block)
    if user_params['editable']
      block.call(self.data)
      self.has_content = true
      if user_params['revision_credit']
        add_user_identifier(user_params['revision_credit'])
      end
      if user_params['clear_revision_id']
        self.data['revisions'] ||= []
        self.data['revisions'] = self.data['revisions'].select{|r| r['id'] != user_params['clear_revision_id'] }
      end
    elsif user_params['user_identifier']
      rev = JSON.parse(self.data.to_json)
      block.call(rev)
      changes = {}
      rev.each do |key, val|
        if val.is_a?(Array)
          objs = self.data[key].map(&:to_json)
          obj_ids = self.data[key].map{|o| o['id'] }.compact
          rev_ids = val.map{|o| o['id'] }.compact
          val.each do |v|
            next if v.is_a?(String)
            if !v['id'] || !obj_ids.include?(v['id'])
              changes[key] ||= []
              v['action'] = 'add'
              changes[key] << v
            elsif !objs.include?(v.to_json)
              changes[key] ||= []
              v['action'] = 'update'
              changes[key] << v
            end
          end
          self.data[key].each do |orig|
            if orig['id'] && !rev_ids.include?(orig['id'])
              changes[key] ||= []
              v = orig.dup
              v['action'] = 'delete'
              changes[key] << v
            end
          end
        elsif val.to_json != self.data[key].to_json
          changes[key] = val
        end
      end
      if changes.keys.length > 0
        pre = self.global_id || (self.data['pre_id'] ||= "p_#{rand(999)}")
        self.data['revisions'] ||= []
        self.data['revisions'] << {
          'user_identifier' => user_params['user_identifier'], 
          'changes' => changes,
          'id' => "#{pre}:#{Time.now.iso8601}_#{rand(9999)}"
        }
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