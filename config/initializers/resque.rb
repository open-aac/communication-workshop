module RedisInit
  cattr_accessor :cache_token
  
  def self.redis_uri
    redis_url = ENV["REDISCLOUD_URL"] || ENV["OPENREDIS_URL"] || ENV["REDISGREEN_URL"] || ENV["REDISTOGO_URL"] || ENV["REDIS_URL"]
    return nil unless redis_url
    URI.parse(redis_url)
  end
  
  def self.init
    uri = redis_uri
    return if !uri && ENV['SKIP_VALIDATIONS']
    raise "redis URI needed for resque" unless uri
    ns_suffix = ""
    if !Rails.env.production?
      ns_suffix = "-#{Rails.env}"
    end
    if defined?(Resque)
      Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      Resque.redis.namespace = "learn_aac#{ns_suffix}"
    end
    redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    @default = Redis::Namespace.new("learn_aac-stash#{ns_suffix}", :redis => redis)
    @permissions = Redis::Namespace.new("learn_aac-permissions#{ns_suffix}", :redis => redis)
    self.cache_token = 'abcdef'
  end
  
  def self.default
    @default
  end
  
  def self.permissions
    @permissions
  end
end

RedisInit.init

require 'permissable'
Permissable.set_redis(RedisInit.permissions, RedisInit.cache_token)
