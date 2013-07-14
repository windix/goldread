# encoding: UTF-8

require 'data_mapper'

# DataMapper::Logger.new($stdout, :debug)

if FreeKindleCN::CONTEXT == :production
  DataMapper.setup(:default, "mysql://root:***REMOVED***@ca2/goldread")
else
  #DataMapper.setup(:default, "sqlite://#{File.expand_path(File.dirname(__FILE__))}/test.db")
  DataMapper.setup(:default, "mysql://root:***REMOVED***@localhost/goldread")
end

DataMapper::Model.raise_on_save_failure = true

module FreeKindleCN
  module DB
    class Item
      include DataMapper::Resource

      storage_names[:default] = "items"

      property :id, Serial
      property :asin, String, :length => 10, :unique => true
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
      property :book_price, Integer
      property :kindle_price, Integer, :index => true
      property :discount_rate, Float, :index => true
      property :created_at, DateTime
      property :updated_at, DateTime
      property :deleted, Boolean, :default => false

      has n, :prices
      has n, :bindings
      has n, :ratings

      # return price fluctuation of previous two prces
      def price_fluc
        # return nil when current price is unavailable
        return nil if kindle_price == -1

        price_changes = prices(:order => [:retrieved_at.desc])

        # defensive code, this case is incorrect
        return nil if price_changes.empty?

        if price_changes.length == 1 # only 1 price, no fluc
          []
        else
          [price_changes[1], price_changes[0]]
        end
      end

      def last_price
        prices(:order => [:retrieved_at.desc]).first.kindle_price rescue nil
      end

      def formatted_discount_rate
        "%.1f折" % (discount_rate.to_f * 10)
      end

      def save_amount
        (book_price - kindle_price).format_price
      end

      def preferred_binding
        @preferred_binding ||= bindings(:preferred => true).first
      end

      def alternate_kindle_versions
        @alternate_kindle_versions ||= bindings(:type => 'kindle')
      end

      def rating_by_source(source = 'amazon')
        ratings(:source => source).first
      end

    end

    class Price
      include DataMapper::Resource

      storage_names[:default] = "prices"

      property :id, Serial
      property :kindle_price, Integer, :index => true
      property :retrieved_at, DateTime

      belongs_to :item
    end

    class Binding
      include DataMapper::Resource

      storage_names[:default] = "bindings"

      property :id, Serial
      property :type, String, :length => 10 # paperback, hardcover
      property :asin, String, :length => 10
      property :isbn, String, :length => 13 # ISBN13 / EAN
      property :douban_id, Integer
      property :preferred, Boolean, :default => false
      property :created_at, DateTime

      def douban_api_url
        "http://api.douban.com/v2/book/#{douban_id}"
      end

      def douban_page_url
        "http://book.douban.com/subject/#{douban_id}/"
      end

      def amazon_url
        "http://www.amazon.cn/dp/#{asin}"
      end

      belongs_to :item
    end

    class Rating
      include DataMapper::Resource

      storage_names[:default] = "ratings"

      property :id, Serial
      property :source, String, :length => 10 # amazon, douban
      property :average, Integer
      property :num_of_votes, Integer
      property :updated_at, DateTime

      def to_s
        "#{average.to_f / 10} (#{num_of_votes})"
      end

      belongs_to :item
    end

  end
end

DataMapper.finalize

# Don't use this
# DataMapper.auto_migrate!

# Only use when DB is upgraded
# DataMapper.auto_upgrade!

