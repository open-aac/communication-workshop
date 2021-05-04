class Lesson < ApplicationRecord
  include SecureSerialize
  include GlobalId
  include Processable
  include Revisions
  include Permissions

  secure_serialize :data
  before_save :generate_defaults

  add_permissions('view', ['*']) { true }
  add_permissions('revise', ['*']) {|user| !!user }
  add_permissions('edit', 'delete') {|user| user.admin? }

  def generate_defaults
    self.data ||= {}
    true
  end

  STRING_PARAMS = ['title', 'body']
  OBJ_PARAMS = ['image', 'sections', 'questions']
  
  def process_params(params, user_params)
    self.generate_defaults
    rev_params = {
      'revision_credit' => params['revision_credit'],
      'clear_revision_id' => params['clear_revision_id']
    }
    if user_params['user']
      rev_params['user_identifier'] = user_params['user']
      rev_params['editable'] = self.allows?(user_params['user'], 'delete')
    end
    self.process_revisions(rev_params) do |hash|
      STRING_PARAMS.each do |string_param|
        hash[string_param] = self.process_string(params[string_param])
      end
      OBJ_PARAMS.each do |obj_param|
        hash[obj_param] = params[obj_param]
      end
    end
    if user_params['user'] && self.allows?(user_params['user'], 'delete')
      if params['add_user_identifier']
        self.add_user_identifier(params['add_user_identifier'])
      end
    end
  end
end

# Module 1
# - Receptive vs. expressive language
# - Multi-modal communication
# - Low-tech and high-tech AAC
# Module 2
# - Presuming competence (least-dangerous assumption)
# - The Importance of Waiting
# - Modeling (hours to proficiency for a verbal communicator)
# - Core and fringe vocabulary (and pre-stored phrases)
# - Motor planning
# Module 3
# - Levels of AAC proficiency
# - Choosing a board size and strategy
# - Planning for long-term growth
# - Symbol selection, button placement strategies
# Module 4
# - Evidence-Based Practice
# - Prompting hierarchy (apraxia, count to ten, warnings against fad strategies)
# - Using data to adapt strategy

# - SHARED READING

# Additional modules
# - Message and Voice Banking
# - Alternative access
# - History and Evolution of AAC
# - Data Logging and Assessments
# - IEP Planning
# - LITERACY
# Other Topics
# - Scanning
# - Eye Gaze
# - Kiosk Mode
# - Data Logging
# - SMP vs. Semantic Compaction
# - AAC Bill of Rights
# - SNUG
# - Iconicity and Symbols or Photos

# Class for Kid Peers
# - We all talk with more than our mouths
# - We each do some things differently!
# - Is talking what makes us smart?
# - What are your 10 favorite words?
# - How would you talk after surgery?
# - Guess what I mean!

# Class for Teen Peers
# - We talk with lots more than our mouths
# - Disability isn't bad
# - What disabilities make you "dumb"?
# - 25-phrase communication challenge
# - Short speech is like a guessing game
# - AAC takes a lot of time and patience (for them and you)
# - Have you ever wanted to be a model?

# Class for Family Members
# - Connection is important for all of us
# - Communication (connection) takes time and repetition
# - Expressive comes after receptive language
# - Talking isn't always an option (even if I CAN talk sometimes)
# - Everyone can model!
# - The dangers of dismissiveness/how will you help?