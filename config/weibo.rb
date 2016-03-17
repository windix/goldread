if FreeKindleCN::CONTEXT == :production
  # production: goldreadchina
  WeiboOAuth2::Config.api_key = '***REMOVED***'
  WeiboOAuth2::Config.api_secret = '***REMOVED***'
  WeiboOAuth2::Config.redirect_uri = 'http://goldread.net/oauth/callback/weibo'

  WEIBO_CONFIG = {
    :access_token => '***REMOVED***',
    :expires => 1530450662
  }
else
  # development: freekindlecn
  WeiboOAuth2::Config.api_key = '***REMOVED***'
  WeiboOAuth2::Config.api_secret = '***REMOVED***'
  WeiboOAuth2::Config.redirect_uri = 'http://127.0.0.1:9292/oauth/callback/weibo'

  WEIBO_CONFIG = {
   :access_token => '***REMOVED***',
   :expires => 1372791599
  }
end
