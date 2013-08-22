# encoding: UTF-8
require 'douban_api'

if FreeKindleCN::CONTEXT == :production
  # production: 金玉良读

  Douban.configure do |config|
    config.client_id = '***REMOVED***'
    config.client_secret = '***REMOVED***'
  end

  DOUBAN_CALLBACK = "http://goldread.net/oauth/callback/douban"

  DOUBAN_CONFIG = {
    :access_token => '5ee592c62c5017aa1cb0b85284f046fe',
    :refresh_token => 'd5067ac18a34007e7f1370449e9c017a',
    :douban_user_name => '***REMOVED***',
    :douban_user_id => ***REMOVED***
  }
else
  # development: 金玉良读测试

  Douban.configure do |config|
    config.client_id = '***REMOVED***'
    config.client_secret = '***REMOVED***'
  end

  DOUBAN_CALLBACK = "http://goldread.dev/oauth/callback/douban"

  DOUBAN_CONFIG = {
    :access_token => 'a8ed88886660becbfac8999933223c61',
    :refresh_token => '1083a2861d8fa427318ae79258aeec75',
    :douban_user_name => '***REMOVED***',
    :douban_user_id => ***REMOVED***
  }
end
