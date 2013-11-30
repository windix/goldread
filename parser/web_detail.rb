# encoding: UTF-8

module FreeKindleCN
  module Parser

    class WebDetail < Base
      attr_reader :ebook_full_price, :paperbook_full_price, :kindle_price, :paperbook_price
      attr_reader :bindings, :average_reviews, :num_of_votes

      def parse
        @ebook_full_price = @paperbook_full_price = @kindle_price = @paperbook_price = -1

        # the bindings do not contain current asin
        @bindings = {}

        parse_with_retry("http://www.amazon.cn/dp/#{@asin}") do |doc|

          # parse prices
          doc.css('table.product tr').each do |tr|
            tds = tr.css('td')

            price = tds[1].text[/￥\s([\d\.]+)/, 1]

            case tds[0].text.strip
            when "电子书定价:"
              @ebook_full_price = parse_price(price)
            when "纸书定价:"
              @paperbook_full_price = parse_price(price)
            when "Kindle电子书价格:"
              @kindle_price = parse_price(price)
            when "价格:" # when parsing paperbook asin
              @paperbook_price = parse_price(price)
            end
          end

          binding_ids = doc.css('table.twisterMediaMatrix table tbody').collect { |t| t['id'] }.compact

          if binding_ids.empty?
            logger.debug "[#{asin}] No binding id found, skip..."
            return false
          end

          binding_ids.each do |binding_id|
            tbody = doc.at_css("tbody##{binding_id}")
            next if tbody.content.strip.empty?

            binding_type = case binding_id
              when "paperback_meta_binding_winner"
                :paperback
              when "hardcover_meta_binding_winner"
                :hardcover
              when "kindle_meta_binding_winner", "kindle_meta_binding_body"
                :kindle
              when "audiobooks_meta_binding_winner", "other_meta_binding_winner"
                # audiobook, skip
                next
              else
                logger.debug "Unknown binding id '#{binding_id}', skip...."
                next
            end

            book_url = tbody.at_css('td.tmm_bookTitle a')

            if book_url
              @bindings[binding_type] = book_url['href'][%r{/dp/([A-Z0-9]+)/}, 1]
            else
              logger.debug "Cannot parse ASIN, skip..." if binding_type != :kindle
              next
            end
          end #binding_ids

          # "平均4.5 星"" -> 4.5
          @average_reviews = doc.at_css('table#productDetailsTable span.crAvgStars span.swSprite').content[/[\d\.]+/].to_f rescue 0.0

          # "56 条商品评论" => 56
          @num_of_votes = doc.at_css('table#productDetailsTable span.crAvgStars > a').content[/[\d,]+/].sub(',', '').to_i rescue 0

          true
        end
      end
    end # class

  end
end
