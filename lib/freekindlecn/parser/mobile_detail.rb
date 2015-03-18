module FreeKindleCN
  module Parser
    # mobile chrome, 这个是可购买的手机版本页面
    class MobileDetail < Base
      attr_reader :ebook_full_price,      # 纸书定价
                  :paperbook_full_price,  # 电子书定价
                  :paperbook_price,       # 纸书特价

                  :kindle_price,          # 电子书特价
                  :book_price             # 图书价格 -- 派生自前三者

      def parse
        parse_with_retry("http://www.amazon.cn/gp/aw/d/#{@asin}", true) do |doc|
          if doc.css('p.infoText').text == '该商品目前无法进行购买'
            # book is temporary unavailable
            @parse_result = RESULT_FAILED
            false

          elsif doc.css('input[name="ASIN.0"]').length == 1
            # book is available
            parse_price_block(doc.css('div#kindle-price-block table tr'))
            true

          else
            # book is permanently unavailable -- the ASIN becomes invalid
            # but we need to verify it: the web dp page will be 404 if it is PERMANENTLY unavailable
            # return nil if HTTPClient.get("http://www.amazon.cn/dp/#{asin}").status_code == 404

            @parser_result = RESULT_DELETED
            false
          end
        end
      end
    end # class

  end
end