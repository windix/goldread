# encoding: UTF-8
require 'douban_api'

if false # FreeKindleCN::CONTEXT == :production
  # production: 金玉良读

  Douban.configure do |config|
    config.client_id = '***REMOVED***'
    config.client_secret = '***REMOVED***'
  end

  DOUBAN_CALLBACK = "http://goldread.net/oauth/callback/douban"

  DOUBAN_CONFIG = {
    :access_token => '148d1edf7d8338d63da75c9e7889aa82',
    :user_id => ***REMOVED***
  }
else
  # development: 金玉良读测试

  Douban.configure do |config|
    config.client_id = '***REMOVED***'
    config.client_secret = '***REMOVED***'
  end

  DOUBAN_CALLBACK = "http://goldread.dev/oauth/callback/douban"
  
  DOUBAN_CONFIG = {
    :access_token => '3d5c8defa6bc7a69b815a9cef4356f3b',
    :user_id => ***REMOVED***
  }
end
