# encoding: UTF-8

require 'sinatra/base'
require 'erb'
require 'chartkick'
require 'open-uri'
require 'json'
require 'twitter-text'
require 'will_paginate-bootstrap'

module FreeKindleCN
  module Web
    class Admin < Sinatra::Base
      configure :development do
        require 'sinatra/reloader'
        register Sinatra::Reloader
      end

      set :views, "#{File.expand_path(File.dirname(__FILE__))}/views/admin"
      # set :public_folder, "#{File.expand_path(File.dirname(__FILE__))}/public"

      helpers WillPaginate::Sinatra::Helpers

      helpers do
        include Twitter::Autolink

        def min_file_suffix
          (settings.environment == :development) ? "" : ".min"
        end

        def price_color(item)
          if item.kindle_price != -1
            if item.price_change
              # price dropped: red / price incresed: blue
              color = item.price_change > 0 ? "blue" : "red"

              result = <<-END
                <span style='color:#{color}'>
                  #{item.p2.format_price}->#{item.p1.format_price}
                </span>
              END
            else
              item.kindle_price.format_price
            end
          else
            "-"
          end
        end

        def prices_data_for_chart(item)
          data = item.prices.collect { |p| [p.retrieved_at, p.kindle_price.to_f / 100] }

          # push current datetime as the endpoint
          data << [Time.now, data.last[1]] unless data.empty?
        end

        def tweet_template(item)
          title_and_author = "#{item.title} - #{item.author}"
          paper_book_price = "纸书#{item.book_price.format_price}"

          if item.price_fluc.nil? or item.price_fluc.empty?
            kindle_book_price = "Kindle版#{item.kindle_price.format_price}"
          else
            kindle_book_price = "Kindle版原价#{item.price_fluc.first.kindle_price.format_price} / 今日特价#{item.price_fluc.last.kindle_price.format_price}"
          end

          discount = "(#{item.formatted_discount_rate}，省#{item.save_amount})"
          url = "购买: http://goldread.net/dp/#{item.asin}"

          "#{title_and_author} #{paper_book_price} / #{kindle_book_price} #{discount} #{url}"
        end

        def tr_color(item)
          if item.deleted
            'error'
          elsif Time.now.to_i - item.updated_at.to_time.to_i < 86400 # 1 day
            'warning'
          else
            nil
          end
        end

        def note(item)
          note = ""

          note += "K" if item.alternate_kindle_bindings_count.to_i > 0
          note += "T" if item.tweeted_at

          # last
          note += "-" if note.empty?

          note
        end

        def item_filter_menu(current_filter)
          current_filter = current_filter.to_sym

          methods = [
            [:added, "Recently Added"],
            [:updated, "Recently Updated"],
            [:price_change, "Price Change"],
            [:discount_rate, "Discount Rate"],
            [:douban_rating, "Douban Rating"],
            [:amazon_rating, "Amazon Rating"]
          ]

          result = ""
          methods.each do |method|
            filter, filter_text = *method

            li_css_class = "class=\"active\"" if filter == current_filter
            filter_url = url("/filter/#{filter}")

            result += <<-END
              <li #{li_css_class}>
                <a href="#{filter_url}">#{filter_text}</a>
              </li>
            END
          end

          result
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
        render_filter(:added) # default filter is :added
      end

      get '/filter/:filter' do
        render_filter(params[:filter])
      end

      get '/dp/:asin' do
        if Item.is_valid_asin?(params[:asin]) &&
          item = DB::Item.first(:asin => params[:asin])

          erb :dp, :locals => { :item => item }
        else
          [404, "Not Found"]
        end
      end

      post '/tweet' do
        tweet = Tweet.new params[:tweet_text],
          params[:tweet_hashtag],
          params[:tweet_upload_picture] ? params[:tweet_image_url] : nil

        result = params[:tweet_to].collect do |t|
          tweet.send("send_to_#{t[0]}") ? 'successful' : tweet.get_error
        end

        result.inspect
      end

      get '/amazon/asin/:asin' do
        client = ASIN::Client.instance
        client.lookup(params[:asin])

        content_type :xml
        client.resp
      end

      get '/tweets' do
        erb :tweets, :locals => { :tweets => DB::TweetArchive.all(:order => [:published_at.desc]) }
      end

      private

      def render_filter(filter)
        view = DB::ItemView.new
        view.set_order(filter.to_sym, :desc)

        erb :index, :locals => { :items => view.fetch(params[:page]), :current_filter => filter }
      end

    end
  end
end
