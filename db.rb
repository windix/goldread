# encoding: UTF-8

require 'data_mapper'

DataMapper.setup(:default, "sqlite://#{File.expand_path(File.dirname(__FILE__))}/test.db")
DataMapper::Model.raise_on_save_failure = true

module FreeKindleCN
  module DB
    class Item
      include DataMapper::Resource

      property :id, Serial
      property :asin, String, :length => 10, :key => true
      property :title, String, :length => 200
      property :details_url, String, :length => 200
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

      private

      def load_price
        latest_price = prices(:order => [:retrieved_at.desc]).first

        if latest_price
          @book_price = latest_price.book_price
          @kindle_price = latest_price.kindle_price
        end
      end
    end

    class Price
      include DataMapper::Resource

      property :id, Serial
      property :book_price, Integer
      property :kindle_price, Integer, :index => true
      property :retrieved_at, DateTime

      belongs_to :item
    end


  end
end

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!

