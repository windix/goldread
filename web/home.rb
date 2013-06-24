# encoding: UTF-8

require 'sinatra/base'
require 'erb'

module FreeKindleCN
  module Web
    class Home < Sinatra::Base
      configure :development do
        require 'sinatra/reloader'
        register Sinatra::Reloader
      end

      set :views, "#{File.expand_path(File.dirname(__FILE__))}/views/home"

      get '/' do
        erb :index
      end

      get '/dp/:asin' do
        if Item.is_valid_asin?(params[:asin]) &&
          item = DB::Item.first(:asin => params[:asin])

          redirect item.details_url
        else
          [404, "Not Found"]
        end
      end

      get '/oauth/callback/weibo' do
        params.inspect

      end

    end
  end
end
