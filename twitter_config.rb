# encoding: UTF-8
require 'twitter'

Twitter.configure do |config|
  # Testing: freekindlecn
  # config.consumer_key = '***REMOVED***'
  # config.consumer_secret = '***REMOVED***'
  # config.oauth_token = '1500289573-***REMOVED***'
  # config.oauth_token_secret = '***REMOVED***'

  # Production: goldreadchina
  config.consumer_key = '***REMOVED***'
  config.consumer_secret = '***REMOVED***'
  config.oauth_token = '***REMOVED***'
  config.oauth_token_secret = '***REMOVED***'
end
