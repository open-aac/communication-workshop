class SessionController < ApplicationController
  def token
    set_browser_token_header
    if params['grant_type'] == 'password'
      pending_u = User.find_for_login(params['username'])
      u = pending_u
      if u && u.valid_password?(params['password'])
        token = u.generate_token!

        render json: JsonApi::Token.as_json(token, u).to_json
      else
        api_error 400, { error: "Invalid authentication attempt" }
      end
    else
      api_error 400, { error: "Invalid authentication approach" }
    end
  end
  
  def token_check
    set_browser_token_header
    if @api_user
      valid = @api_auth.valid_token?(params['access_token'])
      render json: {
        authenticated: valid, 
        user_name: @api_user.settings['user_name']
      }.to_json
    else
      render json: {
        authenticated: false
      }.to_json
    end
  end
end
