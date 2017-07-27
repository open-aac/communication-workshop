class UserWord < ApplicationRecord
  include SecureSerialize
  include GlobalId

  secure_serialize :data
  before_save :generate_defaults
  belongs_to :user
  
  def generate_defaults
    self.data ||= {}
    true
  end
end
