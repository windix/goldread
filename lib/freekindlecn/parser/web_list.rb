module FreeKindleCN
  module Parser

    # 亚马逊排行榜
    class WebList < Base
      attr_reader :asins, :titles, :prices

      # name: 'movers-and-shakers', 'new-releases', 'bestsellers'
      def initialize(name, page = 1, above_the_fold = true)
        @url = self.class.url_for(name, page, above_the_fold)
      end

      def parse
        parse_with_retry(@url) do |doc|
          @asins = doc.css("div.zg_title a").collect { |a| asin_from_url(a['href']) }
          @titles = doc.css("div.zg_title a").collect { |a| a.content }
          @prices = doc.css("div.zg_itemPriceBlock_compact strong.price").collect { |strong| strong.content }
          true
        end
      end

      def self.url_for(name, page = 1, above_the_fold = true)
        node = (name == "bestsellers") ? "116169071" : ""
        above_the_fold_param = above_the_fold ? "" : "&isAboveTheFold=0"

        @url = "http://www.amazon.cn/gp/#{name}/digital-text/#{node}?ie=UTF8&pg=#{page}&ajax=1#{above_the_fold_param}"
      end

    end # class

  end
end