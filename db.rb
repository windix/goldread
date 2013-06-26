# encoding: UTF-8

require 'data_mapper'

# DataMapper::Logger.new($stdout, :debug)

if ENV['RACK_ENV'] == 'production'
  DataMapper.setup(:default, "mysql://root:***REMOVED***@ca2/goldread")
else
  DataMapper.setup(:default, "sqlite://#{File.expand_path(File.dirname(__FILE__))}/test.db")
end

DataMapper::Model.raise_on_save_failure = true

module FreeKindleCN
  module DB
    class Item
      include DataMapper::Resource

      property :id, Serial
      property :asin, String, :length => 10, :key => true
      property :title, String, :length => 200
      property :details_url, String, :length => 1000
      property :review, Text
      property :image_url, String, :length => 200
      property :thumb_url, String, :length => 200
      property :author, String, :length => 100
      property :publisher, String, :length => 100
      property :num_of_pages, Integer, :allow_nil => true
      property :publication_date, Date
      property :release_date, Date
      property :created_at, DateTime
      property :updated_at, DateTime

      has n, :prices

      def book_price
        load_price unless @book_price

        @book_price
      end

      def kindle_price
        load_price unless @kindle_price

        @kindle_price
      end

      def previous_kindle_price
        price_changes = prices(:order => [:retrieved_at.desc])

        if price_changes.length == 1
          price_changes[0].kindle_price
        else
          price_changes[1].kindle_price
        end
      end

      def discount_rate
        load_price unless @kindle_price

        @discount_rate
      end

      def formatted_book_price
        format_price(book_price)
      end

      def formatted_kindle_price
        format_price(kindle_price)
      end

      def formatted_discount_rate
        "%.1f折" % (discount_rate.to_f * 10)
      end

      def formatted_previous_kindle_price
        format_price(previous_kindle_price)
      end

      def save_amount
        format_price(book_price.to_f - kindle_price.to_f)
      end

      private

      def format_price(price)
        if price < 0
          "-"
        else
          "￥%.2f" % (price.to_f / 100)
        end
      end

      def load_price
        price_changes = prices(:order => [:retrieved_at.desc])

        case price_changes.length
        when 0
          return
        when 1
          @previous_price = @current_price = price_changes[0]
        else
          @current_price = price_changes[0]
          @previous_price = price_changes[1]
        end

        @book_price = @current_price.book_price
        @kindle_price = @current_price.kindle_price
        @discount_rate = @current_price.discount_rate
      end
    end

    class Price
      include DataMapper::Resource

      property :id, Serial
      property :book_price, Integer
      property :kindle_price, Integer, :index => true
      property :discount_rate, Float, :index => true
      property :retrieved_at, DateTime

      belongs_to :item
    end


  end
end

DataMapper.finalize

# Don't use this
# DataMapper.auto_migrate!

# Only use when DB is upgraded
# DataMapper.auto_upgrade!

