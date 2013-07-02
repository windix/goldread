# encoding: UTF-8

require 'data_mapper'

# DataMapper::Logger.new($stdout, :debug)

if FreeKindleCN::CONTEXT == :production
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
      property :book_price, Integer
      property :kindle_price, Integer, :index => true
      property :discount_rate, Float, :index => true
      property :created_at, DateTime
      property :updated_at, DateTime
      property :deleted, Boolean, :default => false

      has n, :prices

      def previous_kindle_price
        price_changes = prices(:order => [:retrieved_at.desc])

        if price_changes.length >= 2
          price_changes[1].kindle_price
        else
          nil
        end
      end

      def formatted_discount_rate
        "%.1f折" % (discount_rate.to_f * 10)
      end

      def save_amount
        (book_price - kindle_price).format_price
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

