# encoding: UTF-8

module FreeKindleCN
  module Parser

    class WebDailyDeals < Base
      attr_reader :asins

      def initialize
        @url = "http://www.amazon.cn/gp/feature.html/ref=amb_link_30648212_2?ie=UTF8&docId=126758&pf_rd_m=A1AJ19PSB66TGU&pf_rd_s=right-top&pf_rd_t=101&pf_rd_p=70106812&pf_rd_i=116169071"
      end

      def parse
        parse_with_retry(@url) do |doc|
          # TODO weekly deals

          # doc.at_css('span.price').content
          @asins = []
          doc.css('img[alt="立即购买"]').each do |img|
            @asins << img.parent['href'][%r{/gp/product/([A-Z0-9]+)/}, 1]
          end
          true
        end
      end
    end # class

  end
end
