# encoding: UTF-8

require './freekindlecn'
require './updater'

module FreeKindleCN

  if ARGV.length and Item.is_valid_asin?(ARGV[0])
    Updater.fetch_info(ARGV[0])
  else
    list = AsinList.new

    puts "Daily Deals"
    Updater.fetch_info(list.daily_deal)

    puts "销售飙升榜"
    Updater.fetch_info(list.movers_and_shakers(5))

    puts "新品排行榜"
    Updater.fetch_info(list.new_releases(5))

    paid_best_sellers, free_best_sellers = list.bestsellers(5)

    puts "商品销售榜 (付费)"
    Updater.fetch_info(paid_best_sellers)

    puts "商品销售榜 (免费)"
    Updater.fetch_info(free_best_sellers)
  end

  puts "Done!"

end
