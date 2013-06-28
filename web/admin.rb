# encoding: UTF-8

require 'sinatra/base'
require 'erb'

module FreeKindleCN
  module Web
    class Admin < Sinatra::Base
      configure :development do
        require 'sinatra/reloader'
        register Sinatra::Reloader
      end

      set :views, "#{File.expand_path(File.dirname(__FILE__))}/views/admin"
      # set :public_folder, "#{File.expand_path(File.dirname(__FILE__))}/public"

      helpers do
        def min_file_suffix
          (settings.environment == :development) ? "" : ".min"
        end

        def price_color(item)
          if item.kindle_price < 0
            "-"
          elsif item.previous_kindle_price
            # price dropped: red / price incresed: blue
            color = (item.previous_kindle_price - item.kindle_price > 0) ? "red" : "blue"

            result =<<-END
              <span style='color:#{color}'>
                #{item.previous_kindle_price.format_price}->#{item.kindle_price.format_price}
              </span>
            END
          else
            item.kindle_price.format_price
          end
        end
      end

      def self.new(*)
        app = Rack::Auth::Digest::MD5.new(super) do |username|
          {'***REMOVED***' => '***REMOVED***', '***REMOVED***' => '***REMOVED***'}[username]
        end
        app.realm = 'Protected Area'
        app.opaque = 'secretkey'
        app
      end

      get '/' do
        erb :index, :locals => { :items => DB::Item.all }
      end

      get '/dp/:asin' do
        if Item.is_valid_asin?(params[:asin]) &&
          item = DB::Item.first(:asin => params[:asin])

          erb :dp, :locals => { :item => item }
        else
          [404, "Not Found"]
        end
      end

    end
  end
end
