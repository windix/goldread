require './freekindlecn'
require 'awesome_print'

include FreeKindleCN

tweets = Twitter.user_timeline('goldreadchina', :exclude_replies => true, :trim_user => true, :contributor_details => false, :include_rts => false)

t = tweets.first

p t.created_at
p t.id
p t.text
p t.hashtags.first.text
asin = t.urls.first.expanded_url[/dp\/([A-Z0-9]+)$/, 1]

item = DB::Item.first(:asin => asin)
ap item
