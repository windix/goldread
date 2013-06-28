#!/usr/bin/env ruby
# encoding: UTF-8

require './freekindlecn'
require './updater'
require 'thor'

include FreeKindleCN

class CLI < Thor
  desc "asin", "download by ASIN"
  def asin(*asins)
    Updater.fetch_info(asins.select { |asin| Item.is_valid_asin? asin })
  end

  desc "list", "download by lists"
  def list
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

    puts "Done!"
  end

  desc "all", "refetch price for all books"
  def all
    Updater.fetch_info(DB::Item.all(:fields => [:asin]).collect { |item| item.asin })
  end

end

CLI.start(ARGV)

