module GlobalId
  extend ActiveSupport::Concern

  def global_id
    if self.class.protected_global_id
      if self.nonce == 'legacy'
        self.id ? "1_#{self.id}" : nil
      else
        self.id ? "1_#{self.id}_#{self.nonce}" : nil
      end
    else
      self.id ? "1_#{self.id}" : nil
    end
  end
  
  def related_global_id(id)
    id ? "1_#{id}" : nil
  end
  
  def generate_nonce_if_protected
    if self.class.protected_global_id
      self.nonce ||= GoSecure.nonce('security_nonce')
    end
    true
  end

  module ClassMethods
    def protect_global_id
      self.protected_global_id = true
    end
    
    def find_by_global_id(id)
      hash = id_pieces(id)
      res = find_by(:id => hash[:id])
      if self.protected_global_id && res
        res = nil if !hash[:nonce] && (!res || res.nonce != "legacy")
        res = nil if res && res.nonce != hash[:nonce] && res.nonce != "legacy"
      end
      res
    end
    
    def local_ids(ids)
      raise "not allowed for protected record types" if self.protected_global_id
      ids.map{|id| id.split(/_/)[1] }
    end
    
    def id_pieces(id)
      shard, db_id, nonce = id.to_s.split(/_/); 
      {:shard => shard, :id => db_id, :nonce => nonce}
    end

    def find_by_path(path)
      return nil unless path
      if self == WordData && path.to_s.match(/:/)
        word, locale = path.to_s.split(/:/)
        find_by(:word => word.downcase, :locale => locale.downcase)
      elsif self == WordCategory && path.to_s.match(/:/)
        category, locale = path.to_s.split(/:/)
        find_by(:category => category.downcase, :locale => locale.downcase)
      elsif self == Book && path.to_s.match(/^\d+-/)
        find_by(:ref_id => path.downcase)
      elsif self == Focus && path.to_s.match(/^\d+-/)
        find_by(:ref_id => path.downcase)
      elsif self == User && !path.to_s.match(/^\d/)
        find_by(:hashed_identifier => User.user_name_hash(path))
      else
        find_by_global_id(path)
      end
    end

    def find_all_by_path(paths)
      global_ids = []
      keys = []
      user_names = []
      paths.each do |path|
        if self == Board && path.to_s.match(/\//)
          raise "not allowed on protected records" if self.protected_global_id
          keys << path.downcase
        elsif self == User && !path.to_s.match(/^\d/)
          raise "not allowed on protected records" if self.protected_global_id
          user_names << path.downcase
        else
          global_ids << path
        end
      end
      res = where(:key => keys).to_a
      res += where(:user_name => user_names).to_a
      res += find_all_by_global_id(global_ids).to_a
      res.uniq
    end
    
    def find_all_by_global_id(ids)
      return [] if !ids || ids.length == 0
      id_hashes = (ids || []).map{|id| id_pieces(id) }
      res = self.where(:id => id_hashes.map{|h| h[:id] }).to_a
      if self.protected_global_id
        res = res.select do |record|
          hash = id_hashes.detect{|h| h[:id] == record.id.to_s }
          hash && (record.nonce == 'legacy' || hash[:nonce] == record.nonce)
        end
      end
      res
    end
    
  end
  
  included do
    cattr_accessor :protected_global_id
    before_save :generate_nonce_if_protected
  end
end