# encoding: UTF-8

module FreeKindleCN
  class AsinList

    # 销售飙升榜
    def movers_and_shakers(total_pages = 1)
      handle_page("movers-and-shakers", total_pages)
    end

    # 新品排行榜
    def new_releases(total_pages = 1)
      handle_page("new-releases", total_pages)
    end

    # 商品销售榜 (付费, 免费)
    def bestsellers(total_pages = 1)
      all = handle_page("bestsellers", total_pages)
      [all.odd_values, all.even_values]
    end

    def daily_deal
      parser = Parser::WebDailyDeals.new
      parser.parse

      parser.asin
    end

    private

    def handle_page(name, total_pages)
      all = []

      (1..total_pages).each do |i|
        all += fetch_page(name, i)
      end

      all
    end

    def fetch_page(name, page)
      part1 = Parser::WebList.new(name, page, true)
      part1.parse

      part2 = Parser::WebList.new(name, page, false)
      part2.parse

      part1.asins + part2.asins
    end
  end

end
