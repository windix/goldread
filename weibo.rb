require 'weibo_2'

WeiboOAuth2::Config.api_key = '***REMOVED***'
WeiboOAuth2::Config.api_secret = '***REMOVED***'
WeiboOAuth2::Config.redirect_uri = 'http://127.0.0.1:9292/oauth/callback/weibo' # TODO

client = WeiboOAuth2::Client.new

# puts client.authorize_url

=begin
access_token = client.auth_code.get_token('db41db51bb60b7372b3892c71bfff457')

p access_token.inspect

p access_token.params["uid"]
p access_token.token
p access_token.expires_at
=end

#<OAuth2::AccessToken:0x007f92242d3080>

token = "2.00CuFjqDCUdT6B3a05204a6fRlqQ5C"
expires_at = 1371495600

access_token = client.get_token_from_hash(:access_token => token, :expires_at => expires_at)

p access_token.inspect

p access_token.params["uid"]
p access_token.token
p access_token.expires_at

statuses = client.statuses

p statuses

statuses.update("Test!")
