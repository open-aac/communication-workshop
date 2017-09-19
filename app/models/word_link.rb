class WordLink < ApplicationRecord
  after_create :update_tallies
  after_destroy :update_tallies
  include GlobalId
  
  def update_tallies
    if link_purpose == 'stars'
      # TODO: schedule a recount for stars for the linked word
    end
  end

  def word
  end
  
  def link
  end
end
