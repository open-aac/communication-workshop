class UserAlias < ApplicationRecord
  include SecureSerialize
  include GlobalId

  secure_serialize :settings
  before_save :generate_defaults
  belongs_to :user, optional: true

  def generate_defaults
    self.settings ||= {}
    true
  end
end
