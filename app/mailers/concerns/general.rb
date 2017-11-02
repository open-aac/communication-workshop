require 'aws/ses'

module General
  extend ActiveSupport::Concern
  
  def mail_message(user, subject)
    mail(to: user.settings['email'], subject: "Communication Workshop - #{subject}") if user && user.settings['email']
  end  

  module ClassMethods
    def deliver_message(method_name, *args)
      begin
        method = self.send(method_name, *args)
        method.respond_to?(:deliver_now) ? method.deliver_now : method.deliver
      rescue AWS::SES::ResponseError => e
      end
    end
  end
end