# puts "setting ses"
# ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
#   :access_key_id     => ENV['SES_KEY'] || ENV['AWS_KEY'],
#   :secret_access_key => ENV['SES_SECRET'] || ENV['AWS_SECRET']

Aws::Rails.add_action_mailer_delivery_method(
  :ses,
  credentials: Aws::Credentials.new(
    ENV['SES_KEY'] || ENV['AWS_KEY'],
    ENV['SES_SECRET'] || ENV['AWS_SECRET']
  ),
  region: ENV['SES_REGION']
)
