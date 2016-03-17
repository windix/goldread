require "open-uri"

require 'twitter'
require FreeKindleCN::CONFIG_PATH + '/twitter'

require 'weibo_2'
require FreeKindleCN::CONFIG_PATH + '/weibo'

require 'fb_graph'
require FreeKindleCN::CONFIG_PATH + '/facebook'

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
      page = FbGraph::Page.new(FacebookConfig::PAGE_ID)
      if @image_file
        @image_file.rewind        
        page.photo!(
          :access_token => FacebookConfig::ACCESS_TOKEN,
          :message => @text,
          :source => @image_file,
          :no_story => false,
        )
      else
        page.feed!(
          :access_token => FacebookConfig::ACCESS_TOKEN,
          :message => @text,
          :link => Item.goldread_url(@asin),
        )
      end
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
