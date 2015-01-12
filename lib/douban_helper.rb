# encoding: UTF-8
require 'douban_api'
require 'hashie'
require 'hashie/mash'

require FreeKindleCN::CONFIG_PATH + "/douban"

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
      @client ||= Douban.client(YAML::load_file(config_file))
    end

    def lookup(isbn)
      if isbn.to_s.empty?
        logger.info "Douban: invalid ISBN"
        false
      else
        client.isbn(isbn)
      end
    rescue Douban::Error => e
      if e.code == 6000
        # book_not_found
        logger.info "Douban: cannot find ISBN #{isbn}"
        false

      elsif e.code == 106
        # access_token_has_expired
        refresh_client
        logger.info "Douban: token has been refreshed, retry..."

        # try again
        lookup(isbn)

      else
        raise
      end
    end

    def refresh_client
      resp = client.refresh
      save_config(resp)

      client
    end

    private

    def config_file
      FreeKindleCN::CONFIG_PATH + "/douban.yml"
    end

    def save_config(resp)
      # save douban config to yml
      File.open(config_file, 'w') do |f|
        YAML.dump(resp, f)
      end
    end

  end
end
