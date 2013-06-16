require 'twitter'

Twitter.configure do |config|
  config.consumer_key = 'oqxyOw8ds50RWXTlbJwA'
  config.consumer_secret = 'L1qCCay6GMmMNN1H3J2V76aaViqszvMkQyKGP4uSDQ'
  config.oauth_token = '2936441-qHWJzxIoCGL4l3oD27D9Olr466ot6cDsHQLka70tmg'
  config.oauth_token_secret = 'JdVgY1Jxo3bHpWTP8zCbxHXZx2SFUX47lmzxaE'
end

Twitter.update("Test!")
