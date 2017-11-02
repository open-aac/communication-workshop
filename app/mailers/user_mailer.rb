class UserMailer < ActionMailer::Base
  include General
  default from: "CoughDrop <brian@coughdropaac.com>"
  layout 'email'
  
  def self.bounce_email(email)
    hash = User.email_hash(email)
    users = User.where(:hashed_email => hash)
    users.each do |user|
      user.update_setting('email_disabled', true)
    end
  end
  
  def new_user_registration(user_id)
    @user = User.find_by_global_id(user_id)
    if ENV['NEW_REGISTRATION_EMAIL']
      mail(to: ENV['NEW_REGISTRATION_EMAIL'], subject: "Communication Workshop - New User Registration", reply_to: @user.settings['email'])
    end
  end

  def welcome(user_id)
    @user = User.find_by_global_id(user_id)
    mail_message(@user, "Welcome!")
  end
  
  def forgot_password(user_ids)
    @users = User.find_all_by_global_id(:id => user_ids)
    @user = @users.first if @users.length == 1
    mail_message(@user, "Forgot Password")
  end
end
