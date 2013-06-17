# encoding: UTF-8

require './freekindlecn'

module FreeKindleCN

  list = AsinList.new

  puts "Daily Deals"
  Item.fetch_info(list.daily_deal).each do |item|
    item.save
  end

  puts "销售飙升榜"
  Item.fetch_info(list.movers_and_shakers(5)).each do |item|
    item.save
  end

  puts "新品排行榜"
  Item.fetch_info(list.new_releases(5)).each do |item|
    item.save
  end

  paid_best_sellers, free_best_sellers = list.bestsellers(5)

  puts "商品销售榜 (付费)"
  Item.fetch_info(paid_best_sellers).each do |item|
    item.save
  end

  puts "商品销售榜 (免费)"
  Item.fetch_info(free_best_sellers).each do |item|
    item.save
  end

  puts "Done!"

end