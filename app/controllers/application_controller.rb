class ApplicationController < ActionController::Base
  before_action :set_host
  before_action :check_api_token

  def set_host
    JsonApi::Json.set_host("#{request.protocol}#{request.host_with_port}")
  end

  def check_api_token
    return true unless request.path.match(/^\/api/) || request.path.match(/^\/oauth2/) || params['check_token'] || request.headers['Check-Token']

    @time = Time.now
    Time.zone = nil
    token = params['access_token']
    if !token && request.headers['Authorization']
      match = request.headers['Authorization'].match(/^Bearer ([\w\-_\~]+)$/)
      token = match[1] if match
    end
    @token = token
    if token
      token_data = UserAuth.find_token(@token)
      if !token_data
        set_browser_token_header
        api_error 400, {error: "Invalid token", token: token, invalid_token: true}
        return false      
      elsif token_data[:expired]
        set_browser_token_header
        api_error 400, {error: "Expired token", token: token, invalid_token: true}
        return false
      elsif token_data[:disabled]
        set_browser_token_header
        api_error 400, {error: 'Disabled token', token: token}
        return false
      end
      @api_user = token_data[:user]
      @api_auth = token_data[:auth]
      # TODO: timezone user setting
      Time.zone = "Mountain Time (US & Canada)"

      as_user = params['as_user_id'] || request.headers['X-As-User-Id']
      if @api_user && as_user
        @linked_user = User.find_by_path(as_user)
        if @api_user.admin?
          @true_user = @api_user
          @api_user = @linked_user
        else
          api_error 400, {error: "Invalid mdasquerade attempt", token: token, user_id: as_user}
        end
      end
    end
  end
    
  def allowed?(obj, permission)
    scopes = ['*']
    if @api_user && @api_auth
      scopes = @api_user.permission_scopes
    end
    if !obj || !obj.allows?(@api_user, permission, scopes)
      res = {error: "Not authorized"}
      if permission.instance_variable_get('@scope_rejected')
        res[:scope_limited] = true
      end
      api_error 400, res
      false
    else
      true
    end
  end
  
  def api_error(status_code, hash)
    hash[:status] = status_code
    if hash[:error].blank? && hash['error'].blank?
      hash[:error] = "unspecified error"
    end
    cachey = request.headers['X-Has-AppCache'] || params['nocache']
    render json: hash.to_json, status: (cachey ? 200 : status_code)
  end
  
  def exists?(obj, ref_id=nil)
    if !obj
      res = {error: "Record not found"}
      res[:id] = ref_id if ref_id
      api_error 404, res
      false
    else
      true
    end
  end
  
  def set_browser_token_header
    response.headers['BROWSER_TOKEN'] = GoSecure.browser_token
  end
end
