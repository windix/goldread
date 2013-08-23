# encoding: UTF-8

module FreeKindleCN
  module Parser

    class WebDetail < Base
      attr_reader :bindings, :average_reviews, :num_of_votes

      def parse
        # the bindings do not contain current asin
        @bindings = {}

        parse_with_retry("http://www.amazon.cn/dp/#{@asin}") do |doc|
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
              puts book_url['href']

              @bindings[binding_type] = book_url['href'][%r{/dp/([A-Z0-9]+)/}, 1]
            else
              logger.debug "Cannot parse ASIN, skip..." if binding_type != :kindle
              next
            end
          end #binding_ids

          # "平均4.5 星"" -> 4.5
          @average_reviews = doc.at_css('table#productDetailsTable span.crAvgStars span.swSprite').content[/[\d\.]+/].to_f

          # "56 条商品评论" => 56
          @num_of_votes = doc.at_css('table#productDetailsTable span.crAvgStars > a').content[/[\d,]+/].sub(',', '').to_i

          true
        end
      end
    end # class

  end
end
