# encoding: UTF-8

module FreeKindleCN
  module Parser

    class MobileDetail < Base
      attr_reader :ebook_full_price, :paperbook_full_price, :book_price, :kindle_price, :paperbook_price

      def parse
        parse_with_retry("http://www.amazon.cn/gp/aw/d/#{@asin}", true) do |doc|
          if doc.css('p.infoText').text == '该商品目前无法进行购买'
            # book is temporary unavailable
            return false

          elsif doc.css('input[name="ASIN.0"]').length == 1
            # book is available
            @ebook_full_price, @paperbook_full_price, @book_price, @kindle_price, @paperbook_price = parse_price_block(doc.css('div#kindle-price-block table tr'))
            true
          else
            # book is permanently unavailable -- the ASIN becomes invalid
            # but we need to verify it: the web dp page will be 404 if it is PERMANENTLY unavailable
            # return nil if HTTPClient.get("http://www.amazon.cn/dp/#{asin}").status_code == 404
            false
          end
        end
      end
    end # class

  end
end