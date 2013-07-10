# encoding: UTF-8

require 'sinatra/base'
require 'sinatra-index'
require 'erb'

module FreeKindleCN
  module Web
    class Home < Sinatra::Base
      configure :development do
        require 'sinatra/reloader'
        register Sinatra::Reloader
      end

      register Sinatra::Index
      use_static_index 'index.html'

      set :views, "#{File.expand_path(File.dirname(__FILE__))}/views/home"

#      get '/' do
#        erb :index
#      end

      get '/dp/:asin' do
        if Item.is_valid_asin?(params[:asin]) &&
          item = DB::Item.first(:asin => params[:asin])

          redirect item.details_url
        else
          [404, "Not Found"]
        end
      end

      get '/oauth/weibo' do
        require 'weibo_config'
        client = WeiboOAuth2::Client.new
        redirect client.authorize_url
      end

      get '/oauth/callback/weibo' do
        require 'weibo_config'
        client = WeiboOAuth2::Client.new
        access_token = client.auth_code.get_token(params[:code])

        erb :weibo_callback, :locals => { :access_token => access_token }
      end

      get '/oauth/callback/douban' do
        params.inspect

        3640a1e2a8130cd5

      end


    end
  end
end
