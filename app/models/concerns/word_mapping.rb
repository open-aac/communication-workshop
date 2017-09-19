module WordMapping
  extend ActiveSupport::Concern
  
  def process_map(params)
    # process a manually-entered map
    # images and colors are optional, this can just be a list of available core words for the user
    # this should fork the map if linked to someone else's map (with a UI warning)
  end
  
  def update_map(remote_url=nil)
    # should be manually-updatable from the interface, or triggerable by webhook
    # (when you login as someone from CoughDrop, it should auto-subscribe to webhooks)
    if remote_url && self.settings['external_map']
      # server call to retrieve the latest version of the mapping
      # only persist buttons that are already in the core list
      true
    end
    false
  end 
  
  def manually_update_map
    # schedule an update and return a progress object
  end
  
  def attach_to_map(code)
    # look up the user and if the code is valid, link to their map instead of your own
  end
  
  def full_map(include_supervisees=true)
    # merge the default core list with the user's word map, including
    # supervisees if specified. if multiple results, use voting to select the best result,
    # and include the alternate results as well (but not the default, if that's overriden 
    # everywhere then just drop it)
    # also include an indication of whether the word is in the map, or how many maps it's in
  end
  
  module ClassMethods
    def handle_update(params)
      # find the correct user from the webhook and schedule an update
    end
  end
end