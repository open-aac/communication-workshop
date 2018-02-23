if ENV['RAILS_ENV'] != 'production'
  # TODO: this is a dumb workaround for not understanding how Guard works
  require 'listen/record/symlink_detector'
  module Listen
    class Record
      class SymlinkDetector
        def _fail(_, _)
          fail Error, "Don't watch locally-symlinked directory twice"
        end
      end
    end
  end
end

# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

unless ENV['SKIP_VALIDATIONS']
  require 'go_secure'
  GoSecure.validate_encryption_key
#  raise "DEFAULT_EMAIL_FROM must be defined as environment variable" unless ENV['DEFAULT_EMAIL_FROM']
#  raise "SYSTEM_ERROR_EMAIL must be defined as environment variable" unless ENV['SYSTEM_ERROR_EMAIL']
end


