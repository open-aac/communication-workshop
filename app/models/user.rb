class User < ApplicationRecord
  include SecureSerialize
  include GlobalId

  secure_seralize :settings
  before_save :generate_defaults
  
  def generate_defaults
    self.settings ||= {}
    true
  end
end
