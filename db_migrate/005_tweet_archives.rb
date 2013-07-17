# encoding: UTF-8

=begin

CREATE TABLE IF NOT EXISTS `tweet_archives` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `tweet_id` bigint unsigned DEFAULT NULL,
  `published_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `content` varchar(300) DEFAULT NULL,
  `hashtag` varchar(20) DEFAULT NULL,
  `is_main` tinyint(1) DEFAULT '0',
  `item_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tweet_archives_item` (`item_id`),
  KEY `hashtag` (`hashtag`)
) DEFAULT CHARSET=utf8;

=end

require '../freekindlecn'
require 'cgi'

include FreeKindleCN

# first, collect all tweets

all = []

max_id = 0
loop do
  params = {
    :count => 100,
    :exclude_replies => true,
    :trim_user => true,
    :contributor_details => false,
    :include_rts => false
  }

  params[:max_id] = max_id - 1 unless max_id == 0

  tweets = Twitter.user_timeline('goldreadchina', params)

  break if tweets.length == 0

  all.concat tweets

  max_id = tweets.last.id
end

d "#{all.length} tweets loaded!"

# save to DB!

all.reverse.each do |t|
  hashtag = t.hashtags.first

  if hashtag && (hashtag.text == "Kindle好书推荐" || hashtag.text == "Kindle今日特价书")
    content = CGI.unescape(t.text)

    next if t.urls.empty?

    # store full URLs
    t.urls.each { |url| content.sub!(url.url, url.expanded_url) }

    # remove image URL
    t.media.each { |media| content.sub!(media.url, '') }

    is_main = true
    t.urls.each do |url|
      asin = url.expanded_url[/dp\/([A-Z0-9]+)/, 1]

      item = DB::Item.first(:asin => asin)

      d "#{t.id}, #{hashtag.text}, #{t.created_at} [#{asin}]"

      DB::TweetArchive.create(
        :tweet_id => t.id,
        :published_at => t.created_at,
        :content => content[0...300],
        :hashtag => hashtag.text,
        :is_main => is_main,
        :item_id => item.id
      )

      is_main = false
    end
  end
end

