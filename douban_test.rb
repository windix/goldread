require './freekindlecn'
require 'douban_api'

Douban.configure do |config|
  config.client_id = '0a3828a88d4ff7c61ea879f9a7efe752'
  config.client_secret = '4f8e15984548a938'
end

callback_url = "http://goldread.dev/oauth/callback/douban"
scope = "douban_basic_common,book_basic_r"

# p Douban.authorize_url(:redirect_uri => callback_url, :scope => scope)

code = '3640a1e2a8130cd5'

response = Douban.get_access_token(code, :redirect_uri => callback_url)

p response.access_token
