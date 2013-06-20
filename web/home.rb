# encoding: UTF-8

require 'sinatra/base'
require 'sinatra/reloader'
require 'erb'

module FreeKindleCN
  module Web
    class Home < Sinatra::Base
      configure :development do
        register Sinatra::Reloader
      end

      get '/' do
        "Watch this space!"
      end

      get '/dp/:asin' do
        return 500 unless Item.is_valid_asin?(params[:asin])

        if item = DB::Item.first(:asin => params[:asin])
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
