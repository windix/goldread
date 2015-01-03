# encoding: UTF-8

require "open-uri"
require "twitter_config"
require "weibo_config"
require 'fb_graph'

module FreeKindleCN
  class Tweet
    def initialize(text, tag=nil, image_url=nil, asin=nil)
      @text, @tag, @asin = text, tag, asin
      @image_file = open(image_url) if image_url
    end

    def get_error
      @error
    end

    def send_to_twitter
      if @image_file
        @image_file.rewind
        Twitter.update_with_media @text, @image_file
      else
        Twitter.update @text
      end

      return true
    rescue => e
      @error = e.message
      return false
    end

    def send_to_weibo
      # weibo's hash tag is #xxx#
      weibo_text = @text.sub(@tag, "#{@tag}#")

      if @image_file
        @image_file.rewind
        weibo_client.statuses.upload(weibo_text, @image_file, {
          :filename => 'goldreadchina.jpg',
          :type => 'image/jpeg',
          :name => 'file',
        })
      else
        weibo_client.statuses.update(weibo_text)
      end

      return true
    rescue => e
      @error = e.message
      return false
    end

    def send_to_facebook
      page = FbGraph::Page.new(***REMOVED***)
      page.feed!(
        :access_token => 'CAAMV1jrDfqQBAJWM4dYMKmu3rUcfwittUar7id2ap8YAmZAqcbnW2oIfUYTb4a2pnEDLeL1qRH8ttBBOVmBrRn75kYajYosy2nBe3AZA5SaXLtiPkfESIjqzws7uzEruHjmeZAZB4NwcUhuN6ZBeUci0ol3ZB2sH4rt6vOJYvbLx9HmdZAEUWRoDYQAXppNYgu1qdwCZBtGncgZDZD',
        :message => @text,
        :link => @asin ? "http://www.goldread.net/dp/#{@asin}" : nil,
      )
    end

    private

    def weibo_client
      unless @weibo_client
        @weibo_client = WeiboOAuth2::Client.new
        @weibo_client.get_token_from_hash(WEIBO_CONFIG)
      end

      @weibo_client
    end

  end
end