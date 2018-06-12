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
        user_name: @api_user.settings['user_name'],
        name: @api_user.settings['name']
      }.to_json
    else
      render json: {
        authenticated: false
      }.to_json
    end
  end
  
  def user_redirect
    user = User.find_by_path(params['user_id'])
    if user
      if user.settings['url']
        redirect_to user.settings['url']
      else
        redirect_to "/users/#{user.settings['user_name']}?link=1"
      end
    else
      redirect_to '/'
    end
  end

  def coughdrop_auth
    if params['id'] == 'check'
      if ENV['COUGHDROP_HOST'] && ENV['COUGHDROP_CLIENT_ID']
        redirect_to "#{ENV['COUGHDROP_HOST']}/oauth2/token?client_id=#{ENV['COUGHDROP_CLIENT_ID']}&scope=read_profile:basic_supervision&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
      else
        render text: "CoughDrop not configured"
      end
    elsif params['id'] == 'confirm'
      if !ENV['COUGHDROP_CLIENT_ID'] || !ENV['COUGHDROP_CLIENT_SECRET']
        api_error 400, {error: "CoughDrop not configured"}
      elsif params['code']
        res = Typhoeus.post("#{ENV['COUGHDROP_HOST']}/oauth2/token", body: {
          client_id: ENV['COUGHDROP_CLIENT_ID'],
          client_secret: ENV['COUGHDROP_CLIENT_SECRET'],
          code: params['code']
        })
        json = JSON.parse(res.body) rescue nil
        return api_error(400, {error: "Invalid response"}) unless json
        token = json
        res = Typhoeus.get("#{ENV['COUGHDROP_HOST']}/api/v1/users/self?access_token=#{token['access_token']}")
        json = JSON.parse(res.body) rescue nil
        return api_error(400, {error: "Error retrieving user details", src: res.body}) unless json && json['user']
        user = json['user']
        
        local_user = User.assert_user!({
          remote_user_name: token['user_name'],
          remote_anonymized_user_id: token['anonymized_user_id'],
          remote_name: user['name'],
          email: user['email'],
          access_token: token['access_token'],
          source: 'coughdrop',
          current_user: @api_user,
          metadata: {
            scopes: token['scopes']
          }
        })
        token = local_user.generate_token!
        render json: JsonApi::Token.as_json(token, local_user).to_json
      else
        api_error 400, {error: "Code missing from response"}
      end
    end
  end
end
