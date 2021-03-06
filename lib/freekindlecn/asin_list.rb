module FreeKindleCN
  class AsinList

    # 销售飙升榜
    def movers_and_shakers(total_pages = 1)
      asins = handle_page("movers-and-shakers", total_pages)
      update_list('movers-and-shakers', asins)

      asins
    end

    # 新品排行榜
    def new_releases(total_pages = 1)
      asins = handle_page("new-releases", total_pages)
      update_list('new-releases', asins)

      asins
    end

    # 商品销售榜 (付费, 免费)
    def bestsellers(total_pages = 1)
      total_paid_asins, total_free_asins = [], []

      (1..total_pages).each do |i|
        paid_asins, free_asins = best_seller_parser(i)

        total_paid_asins += paid_asins
        total_free_asins += free_asins
      end

      update_list('paid-bestsellers', total_paid_asins)
      update_list('free-bestsellers', total_free_asins)

      [total_paid_asins, total_free_asins]
    end

    def daily_deal
      asins = daily_deal_parser.daily_asins
      update_list('daily-deals', asins)

      asins
    end

    def weekly_deal
      asins = daily_deal_parser.weekly_asins
      update_list('weekly-deals', asins)

      asins
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

    def best_seller_parser(page)
      paid_asins, free_asins = [], []

      [true, false].each do |option|
        part = Parser::WebList.new('bestsellers', page, option)
        part.parse

        part.prices.each_with_index do |price, index|
          if price == '免费'
            free_asins << part.asins[index]
          else
            paid_asins << part.asins[index]
          end
        end
      end

      [paid_asins, free_asins]
    end

    def daily_deal_parser
      unless @daily_deal_parser
        @daily_deal_parser = Parser::WebDailyDeals.new
        @daily_deal_parser.parse
      end

      @daily_deal_parser
    end

    def update_list(list_type, asins)
      DB::List.all(:type => list_type).destroy

      asins.each do |asin|
        DB::List.create(:type => list_type, :asin => asin)
      end
    end

    def self.get_all
      all_lists = {
        'daily-deals' => '每日特价',
        'weekly-deals' => '每周特价',
        'movers-and-shakers' => '销售飙升榜',
        'new-releases' => '新品排行榜',
        'paid-bestsellers' => '商品销售榜(付费)',
        'free-bestsellers' => '商品销售榜(免费)',
      }

      all_lists.collect do |type, name|
        view = DB::ItemView.new
        view.list_type = type
        view.set_order(:list, :asc)

        {
          :name => name,
          :items => view.fetch
        }
      end
    end

  end

end
