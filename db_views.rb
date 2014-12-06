# encoding: UTF-8

require 'will_paginate/array'

module FreeKindleCN
  module DB
    class ItemView

      attr_accessor :list_type

      def set_order(method, order = :desc)
        @use_pagination = true

        case method
        when :added
          @order_sql = "ORDER BY created_at %ORDER%, id %ORDER%"
        when :updated
          @order_sql = "ORDER BY updated_at %ORDER%, id %ORDER%"
        when :price_change
          @order_sql = "ORDER BY price_change %ORDER%, id %ORDER%"
          @filter_sql = "HAVING price_change IS NOT NULL"
        when :price_change_count
          @order_sql = "ORDER BY price_change_count %ORDER%"
        when :discount_rate
          @order_sql = "ORDER BY discount_rate %ORDER%, id %ORDER%"
          @filter_sql = "HAVING kindle_price != 0"
        when :douban_rating
          @order_sql = "ORDER BY douban_average %ORDER%, douban_votes %ORDER%, id %ORDER%"
        when :amazon_rating
          @order_sql = "ORDER BY amazon_average %ORDER%, amazon_votes %ORDER%, id %ORDER%"
        when :all
          @order_sql = "ORDER BY id %ORDER%"
          @use_pagination = false
        when :book_price
          @order_sql = "ORDER BY book_price %ORDER%"
        when :kindle_price
          @order_sql = "ORDER BY kindle_price %ORDER%"
        when :free
          @order_sql = "ORDER BY id %ORDER%"
          @filter_sql = "HAVING kindle_price = 0"
        when :list
          @join_with_lists_sql = "LEFT JOIN lists ON (lists.asin = items.asin AND lists.type = '#{@list_type}')"
          @order_sql = "ORDER BY lists.id %ORDER%"
          @use_pagination = false
        end

        @order_sql.gsub! "%ORDER%", (order == :asc) ? "ASC" : "DESC"
      end

      def fetch(page = 1)
        if @use_pagination
          repository(:default).adapter.select(build_query).paginate :page => page, :per_page => ADMIN_ITEMS_PER_PAGE
        else
          repository(:default).adapter.select(build_query)
        end
      end

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
            prices_count.count AS price_change_count,
            items.discount_rate,
            items.created_at,
            items.updated_at,
            items.deleted,
            bindings.asin AS book_asin,
            bindings.douban_id,
            alternate_kindle_bindings.count AS alternate_kindle_bindings_count,
            amazon.average AS amazon_average,
            amazon.num_of_votes AS amazon_votes,
            douban.average AS douban_average,
            douban.num_of_votes AS douban_votes,
            tweet_archives.published_at AS tweeted_at
        FROM items
        LEFT JOIN prices AS last_price ON (last_price.item_id = items.id AND last_price.orders = -1)
        LEFT JOIN prices AS second_last_price ON (second_last_price.item_id = items.id AND second_last_price.orders = -2)
        LEFT JOIN (SELECT COUNT(*) AS count, item_id
                  FROM prices
                  GROUP BY item_id) AS prices_count ON (prices_count.item_id = items.id)
        LEFT JOIN bindings ON (bindings.item_id = items.id AND bindings.preferred = 1)
        LEFT JOIN (SELECT COUNT(*) AS count, item_id
                  FROM bindings
                  WHERE type = 'kindle'
                  GROUP BY item_id) AS alternate_kindle_bindings ON (alternate_kindle_bindings.item_id = items.id)
        LEFT JOIN ratings AS amazon ON (amazon.item_id = items.id AND amazon.source = 'amazon')
        LEFT JOIN ratings AS douban ON (douban.item_id = items.id AND douban.source = 'douban')
        LEFT JOIN tweet_archives ON (tweet_archives.item_id = items.id)
        #{@join_with_lists_sql}
        GROUP BY items.id
        #{@filter_sql}
        #{@order_sql}
        "
      end

    end
  end
end