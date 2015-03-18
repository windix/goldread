module FreeKindleCN
  module Parser

    class WebDetail < Base

      # note the price are based in cents
      attr_reader :ebook_full_price,      # 纸书定价
                  :paperbook_full_price,  # 电子书定价
                  :paperbook_price,       # 纸书特价

                  :kindle_price,          # 电子书特价
                  :book_price             # 图书价格 -- 派生自前三者

      attr_reader :bindings, :average_reviews, :num_of_votes

      def parse
        parse_with_retry("http://www.amazon.cn/dp/#{@asin}") do |doc|
          # verify asin from page and the asin passed in
          if asin == 'ASIN'
            # hack for testing -- set correct ASIN
            @asin = parse_asin(doc)
          elsif parse_asin(doc) != @asin
            @parse_result = RESULT_FAILED
            return false
          end

          parse_price_block(doc.css('table.product tr'))

          parse_bindings(doc)

          parse_average_views(doc)

          parse_num_of_votes(doc)

          true
        end
      end

      private

      def parse_asin(doc)
        asin_from_url(doc.at_css('link[rel=canonical]')['href']) rescue nil
      end

      def parse_bindings(doc)
        # bindings do not contain current (kindle) asin
        @bindings = {}

        binding_ids = doc.css('table.twisterMediaMatrix table tbody').collect { |t| t['id'] }.compact

        if binding_ids.empty?
          logger.debug "[#{asin}] No binding found, skip..."
          return false
        end

        binding_ids.each do |binding_id|
          tbody = doc.at_css("tbody##{binding_id}")
          next if tbody.content.strip.empty?

          binding_type = case binding_id
            when "paperback_meta_binding_winner", "mass_market_paperback_meta_binding_winner"
              :paperback
            when "hardcover_meta_binding_winner"
              :hardcover
            when "kindle_meta_binding_winner", "kindle_meta_binding_body"
              :kindle
            when "audiobooks_meta_binding_winner", "other_meta_binding_winner",
              "audio_cd_meta_binding_winner", "audio_cassette_meta_binding_winner"
              # audiobook, skip
              next
            else
              logger.debug "Unknown binding id '#{binding_id}', skip...."
              next
          end

          book_url = tbody.at_css('td.tmm_bookTitle a')

          if book_url
            @bindings[binding_type] = asin_from_url(book_url['href'])
          else
            logger.debug "Cannot parse ASIN, skip..." if binding_type != :kindle
            next
          end
        end #binding_ids
      end

      def parse_average_views(doc)
        # "平均4.5 星"" -> 4.5
        @average_reviews = doc.at_css('div#detail_bullets_id span.crAvgStars span.swSprite').content[/[\d\.]+/].to_f rescue 0.0
      end

      def parse_num_of_votes(doc)
        # "56 条商品评论" => 56
        @num_of_votes = doc.at_css('div#detail_bullets_id span.crAvgStars > a').content[/[\d,]+/].sub(',', '').to_i rescue 0
      end

    end # class

  end
end
