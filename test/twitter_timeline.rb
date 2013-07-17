# encoding: UTF-8

require '../freekindlecn'
require 'awesome_print'

include FreeKindleCN

tweets = Twitter.user_timeline('goldreadchina', :exclude_replies => true, :trim_user => true, :contributor_details => false, :include_rts => false)

#t = tweets.first

tweets.each do |t|
  hash = t.hashtags.first

  if hash && (hash.text == "Kindle好书推荐" || hash.text == "Kindle每日特价")
    content = t.text

    t.urls.each { |url| content.sub!(url.url, '') }
    t.media.each { |media| content.sub!(media.url, '') }

    p content
  end
end

__END__

p t.created_at
p t.id
p t.text




p t.hashtags.first.text
asin = t.urls.first.expanded_url[/dp\/([A-Z0-9]+)$/, 1]

item = DB::Item.first(:asin => asin)
ap item.attributes
