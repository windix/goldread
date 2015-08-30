module FreeKindleCN
  module Parser

    class WebDailyDeals < Base
      attr_reader :daily_asins, :weekly_asins

      def initialize
        @url = "http://www.amazon.cn/gp/feature.html/ref=amb_link_30648212_2?ie=UTF8&docId=126758&pf_rd_m=A1AJ19PSB66TGU&pf_rd_s=right-top&pf_rd_t=101&pf_rd_p=70106812&pf_rd_i=116169071"
      end

      def parse
        parse_with_retry(@url) do |doc|
          # daily deals
          @daily_asins = []
          doc.css('div.unified_widget').first.css('a').each do |a|
            asin = asin_from_url(a['href'])
            @daily_asins << asin if asin
          end

          # weekly deals
          @weekly_asins = []
          doc.css('div.unified_widget').last.css('a').each do |a|
            asin = asin_from_url(a['href'])
            @weekly_asins << asin if asin
          end

          @weekly_asins.uniq!

          true
        end
      end
    end # class

  end
end
