module FreeKindleCN
  module Parser

    class WebDailyDeals < Base
      attr_reader :daily_asins, :weekly_asins

      def initialize
	@url = "http://www.amazon.cn/gp/feature.html/ref=cp_bm_kindlebooksKDD?ie=UTF8&docId=126758"
      end

      def parse
        parse_with_retry(@url) do |doc|
          # daily deals
          @daily_asins = []
          doc.css('div.unified_widget').first.css('div.s9OtherItems div.asin a.title').each do |a|
            asin = asin_from_url(a['href'])
            @daily_asins << asin if asin
          end

          # weekly deals
          @weekly_asins = []
          doc.css('div.unified_widget').last.css('div.s9OtherItems div.asin a.title').each do |a|
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
