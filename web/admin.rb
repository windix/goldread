# encoding: UTF-8

require 'sinatra/base'
require 'sinatra/reloader'
require 'erb'

module FreeKindleCN
  module Web
    class Admin < Sinatra::Base
      configure :development do
        register Sinatra::Reloader
      end

      set :views, "#{File.expand_path(File.dirname(__FILE__))}/views/admin"

      get '/' do
        erb :index, :locals => { :items => DB::Item.all }
      end

      get '/oauth/callback/weibo' do
        params.inspect

      end

    end
  end
end
