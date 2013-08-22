# encoding: UTF-8
require 'douban_api'

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

class DoubanHelper
  class << self
    def auth_url
      Douban.authorize_url(:redirect_uri => DOUBAN_CALLBACK, :scope => DOUBAN_SCOPE)
    end

    # code is from param[:code]
    def handle_callback(code)
      resp = Douban.get_access_token(code, :redirect_uri => DOUBAN_CALLBACK)
      save_config(resp)
    end

    def client
      Douban.client(config)
    end

    def refresh_client
      client = self.client
      resp = client.refresh
      save_config(resp)

      client
    end

    private

    def config_file
      File.expand_path('../douban.yml', __FILE__)
    end

    def save_config(resp)
      # save douban config to yml
      File.open(config_file, 'w') do |f|
        YAML.dump(resp, f)
      end
    end

    def config
      # http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash
      YAML::load_file(config_file).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    end
  end
end
