require 'sinatra/base'
require 'sinatra-index'
require 'erb'
require 'chartkick'

module FreeKindleCN
  module Web
    class Home < Sinatra::Base
      configure :development do
        require 'sinatra/reloader'
        register Sinatra::Reloader
      end

      register Sinatra::Index
      use_static_index 'index.html'

      set :views, "#{__dir__}/views/home"

      helpers do
        # TODO shared from admin
        def min_file_suffix
          (settings.environment == :development) ? "" : ".min"
        end

        def prices_data_for_chart(item)
          data = item.prices.collect { |p| [p.retrieved_at, p.kindle_price.to_f / 100] }

          # push current datetime as the endpoint
          data << [Time.now, data.last[1]] unless data.empty?
        end
      end


#      get '/' do
#        erb :index
#      end

      get '/dp/:asin' do
        if Item.is_valid_asin?(params[:asin]) &&
          item = DB::Item.first(:asin => params[:asin])

          erb :dp, :locals => { :item => item }
        else
          [404, "Not Found"]
        end
      end

      get '/oauth/weibo' do
        client = WeiboOAuth2::Client.new
        redirect client.authorize_url
      end

      get '/oauth/callback/weibo' do
        client = WeiboOAuth2::Client.new
        access_token = client.auth_code.get_token(params[:code])

        erb :weibo_callback, :locals => { :access_token => access_token }
      end

      get '/oauth/douban' do
        redirect DoubanHelper.auth_url
      end

      get '/oauth/callback/douban' do
        DoubanHelper.handle_callback(params[:code])

        "Done!"
      end

    end
  end
end
