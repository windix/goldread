# encoding: UTF-8

require 'will_paginate/array'

module FreeKindleCN
  module DB
    class ItemView

      def set_order(method, order = :desc)
        case method
        when :added
          @order_sql = "ORDER BY created_at"
        when :updated
          @order_sql = "ORDER BY updated_at"
        when :price_change
          @order_sql = "ORDER BY price_change"
        when :discount_rate
          @order_sql = "ORDER BY discount_rate"
        when :douban_rating
          @order_sql = "ORDER BY douban_average"
        end

        @order_sql += (order == :asc) ? " ASC" : " DESC";
      end

      def fetch(page = 1)
        repository(:default).adapter.select(build_query).paginate :page => page, :per_page => ADMIN_ITEMS_PER_PAGE
      end

      private

      def build_query
        "SELECT items.id,
            items.asin,
            items.title,
            items.author,
            items.details_url,
            items.book_price,
            items.kindle_price,
            last_price.kindle_price AS p1,
            second_last_price.kindle_price AS p2,
            (last_price.kindle_price - second_last_price.kindle_price) AS price_change,
            items.discount_rate,
            items.created_at,
            items.updated_at,
            items.deleted,
            bindings.asin AS book_asin,
            bindings.douban_id,
            amazon.average AS amazon_average,
            amazon.num_of_votes AS amazon_votes,
            douban.average AS douban_average,
            douban.num_of_votes AS douban_votes,
            tweet_archives.published_at AS tweeted_at
        FROM items
        LEFT JOIN prices AS last_price ON (last_price.item_id = items.id AND last_price.orders = -1)
        LEFT JOIN prices AS second_last_price ON (second_last_price.item_id = items.id AND second_last_price.orders = -2)
        LEFT JOIN bindings ON (bindings.item_id = items.id AND bindings.preferred = 1)
        LEFT JOIN ratings AS amazon ON (amazon.item_id = items.id AND amazon.source = 'amazon')
        LEFT JOIN ratings AS douban ON (douban.item_id = items.id AND douban.source = 'douban')
        LEFT JOIN tweet_archives ON (tweet_archives.item_id = items.id)
        GROUP BY items.id
        #{@order_sql}
        "
      end

    end
  end
end