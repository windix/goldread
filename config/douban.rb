# encoding: UTF-8

DOUBAN_SCOPE = 'douban_basic_common,book_basic_r'

if FreeKindleCN::CONTEXT == :production
  # production: 金玉良读

  Douban.configure do |config|
    config.client_id = '***REMOVED***'
    config.client_secret = '***REMOVED***'
  end

  DOUBAN_CALLBACK = "http://goldread.net/oauth/callback/douban"
else
  # development: 金玉良读测试

  Douban.configure do |config|
    config.client_id = '***REMOVED***'
    config.client_secret = '***REMOVED***'
  end

  DOUBAN_CALLBACK = "http://goldread.dev/oauth/callback/douban"
end
