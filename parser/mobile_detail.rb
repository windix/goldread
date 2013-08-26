# encoding: UTF-8

module FreeKindleCN
  module Parser

    class MobileDetail < Base
      attr_reader :book_price, :kindle_price

      def parse
        @book_price = @kindle_price = -1

        parse_with_retry("http://www.amazon.cn/gp/aw/d/#{@asin}", true) do |doc|
          if doc.css('p.infoText').text == '该商品目前无法进行购买'
            # book is temporary unavailable
            return false

          elsif doc.css('input[name="ASIN.0"]').length == 1
            # book is available
            if (doc.css('span.listPrice').last && doc.at_css('span.kindlePrice'))
              # listPrice有两个通常：电子书定价 / 纸书定价，一些情况下只有电子书定价
              @book_price = parse_price(doc.css('span.listPrice').last.content)
              @kindle_price = parse_price(doc.at_css('span.kindlePrice').content)
              return true
            else
              logger.info "*************************************************"
              logger.info @content
              logger.info "*************************************************"
              return false
            end
          else
            # book is permanently unavailable -- the ASIN becomes invalid
            # but we need to verify it: the web dp page will be 404 if it is PERMANENTLY unavailable
            # return nil if HTTPClient.get("http://www.amazon.cn/dp/#{asin}").status_code == 404
            return false
          end
        end
      end
    end # class

  end
end