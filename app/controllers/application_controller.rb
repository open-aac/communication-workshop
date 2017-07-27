class ApplicationController < ActionController::Base
  
  def allowed?(obj, permission)
    scopes = ['*']
    if @api_user && @api_device
      @api_user.permission_scopes_device = @api_device
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
end
