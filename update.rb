# encoding: UTF-8

require './freekindlecn'
require './updater'

module FreeKindleCN

  if ARGV.length and Item.is_valid_asin?(ARGV[0])
    Updater.fetch_info(ARGV[0]).first.save
  else
    list = AsinList.new

    puts "Daily Deals"
    Updater.fetch_info(list.daily_deal).each do |item|
      item.save
    end

    puts "销售飙升榜"
    Updater.fetch_info(list.movers_and_shakers(5)).each do |item|
      item.save
    end

    puts "新品排行榜"
    Updater.fetch_info(list.new_releases(5)).each do |item|
      item.save
    end

    paid_best_sellers, free_best_sellers = list.bestsellers(5)

    puts "商品销售榜 (付费)"
    Updater.fetch_info(paid_best_sellers).each do |item|
      item.save
    end

    puts "商品销售榜 (免费)"
    Updater.fetch_info(free_best_sellers).each do |item|
      item.save
    end
  end

  puts "Done!"

end
