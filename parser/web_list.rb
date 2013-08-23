# encoding: UTF-8

module FreeKindleCN
  module Parser

    class WebList < Base
      attr_reader :asins, :titles

      # name: 'movers-and-shakers', 'new-releases', 'bestsellers'
      def initialize(name, page = 1, above_the_fold = true)
        node = (name == "bestsellers") ? "116169071" : ""
        above_the_fold_param = above_the_fold ? "" : "&isAboveTheFold=0"

        @url = "http://www.amazon.cn/gp/#{name}/digital-text/#{node}?ie=UTF8&pg=#{page}&ajax=1#{above_the_fold_param}"
      end

      def parse
        parse_with_retry(@url) do |doc|
          @asins = doc.css("span.asinReviewsSummary").collect { |span| span['name'] }
          @titles = doc.css("div.zg_title a").collect { |a| a.content }
          true
        end
      end
    end # class

  end
end