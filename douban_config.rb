# encoding: UTF-8
require 'douban_api'

if FreeKindleCN::CONTEXT == :production
  Douban.configure do |config|
    config.client_id = '***REMOVED***'
    config.client_secret = '***REMOVED***'
  end

  DOUBAN_CALLBACK = "http://goldread.net/oauth/callback/douban"


else
  Douban.configure do |config|
    config.client_id = '0a3828a88d4ff7c61ea879f9a7efe752'
    config.client_secret = '4f8e15984548a938'
  end

  DOUBAN_CALLBACK = "http://goldread.dev/oauth/callback/douban"

  DOUBAN_CONFIG = {
    :access_token => '989b86dd0e8c905dc9d294972ba5b117',
    :user_id => ***REMOVED***
  }
end
