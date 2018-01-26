class UserAuth < ApplicationRecord
  include SecureSerialize
  include GlobalId

  secure_serialize :settings
  before_save :generate_defaults
  belongs_to :user
  
  def generate_defaults
    self.settings ||= {}
    self.settings['tokens'] ||= []
    true
  end
  
  def self.find_token(token)
    user_id, extra = token.to_s.split(/-/)
    user = User.find_by_global_id(user_id)
    auth = user && UserAuth.find_by(:user_id => user.id)
    return nil unless user && auth
    match = auth.settings['tokens'].detect{|t| t['key'] == token }
    now = Time.now.iso8601
    return nil unless match
    {
      user: user,
      auth: auth,
      expired: !!(match['expires'] < now),
      disabled: !!match['disabled']
    }
  end
  
  def valid_token?(token)
    match = (self.settings['tokens'] || []).detect{|t |t['key'] == token }
    now = Time.now.iso8601
    cutoff = 3.weeks.ago.iso8601
    if !!(match && match['expires'] > now && match['used'] > cutoff)
      if match['used'] < 2.days.ago.iso8601
        match['used'] = now
        self.save
      end
      return true
    else
      return false
    end
  end
  
  def generate_token!
    cutoff = 3.weeks.ago.iso8601
    tokens = (self.settings['tokens'] || []).select{|t| t['used'] > cutoff }
    now = Time.now.iso8601
    nonce = GoSecure.sha512(GoSecure.nonce('user auth token'), 'user auth token big')
    key = "#{self.user.global_id}-#{nonce}"
    tokens << {
      'used' => now,
      'expires' => 6.months.from_now.iso8601,
      'key' => key
    }
    self.settings['tokens'] = tokens
    self.save
    key
  end
end
