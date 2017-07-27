class User < ApplicationRecord
  include SecureSerialize
  include GlobalId

  secure_serialize :settings
  before_save :generate_defaults
  
  def generate_defaults
    self.settings ||= {}
    true
  end
end
