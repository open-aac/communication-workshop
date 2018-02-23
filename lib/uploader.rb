require 'typhoeus'

module Uploader
  S3_EXPIRATION_TIME=60*60
  CONTENT_LENGTH_RANGE=100.megabytes.to_i

  def self.check_existing_upload(remote_path)
    if remote_path && ENV['UPLOADS_S3_CDN']
      url = "#{ENV['UPLOADS_S3_CDN']}/#{remote_path}"
      res = Typhoeus.head(url)
      if res.code == 200
        valid = true
        if res.headers['x-amz-expiration']
          exp = res.headers['x-amz-expiration'].match(/expiry-date="([^\"]+)"/)[1]
          exp = Time.parse(exp) rescue nil
          if exp && exp < 48.hours.from_now
            valid = false
          end
        end
        return url if valid
      end
    end
    return nil
    # TODO: if the path exists and won't expire for at least 48 hours
    # then return the existing record URL
  end

  
  def self.remote_upload(remote_path, local_path, content_type)
    params = remote_upload_params(remote_path, content_type)
    post_params = params[:upload_params]
    return nil unless File.exist?(local_path)
    post_params[:file] = File.open(local_path, 'rb')

    # upload to s3 from tempfile
    res = Typhoeus.post(params[:upload_url], body: post_params)
    if res.success?
      return (remote_upload_config[:upload_cdn] || params[:upload_url]) + remote_path
    else
      return nil
    end
  end

  def self.remote_upload_params(remote_path, content_type)
    config = remote_upload_config
    
    res = {
      :upload_url => config[:upload_url],
      :upload_params => {
        'AWSAccessKeyId' => config[:access_key]
      }
    }
    
    policy = {
      'expiration' => (S3_EXPIRATION_TIME).seconds.from_now.utc.iso8601,
      'conditions' => [
        {'key' => remote_path},
        {'acl' => 'public-read'},
        ['content-length-range', 1, (CONTENT_LENGTH_RANGE)],
        {'bucket' => config[:bucket_name]},
        {'success_action_status' => '200'},
        {'content-type' => content_type}
      ]
    }
    # TODO: for pdfs, policy['conditions'] << {'content-disposition' => 'inline'}

    policy_encoded = Base64.encode64(policy.to_json).gsub(/\n/, '')
    signature = Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha1'), config[:secret], policy_encoded
      )
    ).gsub(/\n/, '')

    res[:upload_params].merge!({
       'key' => remote_path,
       'acl' => 'public-read',
       'policy' => policy_encoded,
       'signature' => signature,
       'Content-Type' => content_type,
       'success_action_status' => '200'
    })
    res
  end
  
  def self.remote_upload_config
    @remote_upload_config ||= {
      :upload_url => "https://#{ENV['UPLOADS_S3_BUCKET']}.s3.amazonaws.com/",
      :upload_cdn => "#{ENV['UPLOADS_S3_CDN']}/",
      :access_key => ENV['AWS_KEY'],
      :secret => ENV['AWS_SECRET'],
      :bucket_name => ENV['UPLOADS_S3_BUCKET']
    }
  end
end