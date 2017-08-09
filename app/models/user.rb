class User < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable

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
end
