#!/usr/bin/env ruby

require __dir__ + '/../bootstrap'
require 'thor'

include FreeKindleCN

class CLI < Thor
  desc "asin", "download by ASIN"
  def asin(*asins)
    Updater.fetch_info(asins.select { |asin| Item.is_valid_asin? asin })
  end

  desc "list", "download by lists"
  def list
    logger.info "#{Time.now}: Updating lists..."

    list = AsinList.new

    logger.info "Daily Deals"
    Updater.fetch_info(list.daily_deal)

    logger.info "Weekly Deals"
    Updater.fetch_info(list.weekly_deal)

    logger.info "销售飙升榜"
    Updater.fetch_info(list.movers_and_shakers(5))

    logger.info "新品排行榜"
    Updater.fetch_info(list.new_releases(5))

    paid_best_sellers, free_best_sellers = list.bestsellers(5)

    logger.info "商品销售榜 (付费)"
    Updater.fetch_info(paid_best_sellers)

    logger.info "商品销售榜 (免费)"
    Updater.fetch_info(free_best_sellers)

    logger.info "Done!"
  end

  desc "all", "refetch price for all books (exclude deleted)"
  def all
    logger.info "#{Time.now}: Updating all..."

    Updater.fetch_info(DB::Item.all(:deleted => false, :fields => [:asin]).collect { |item| item.asin })
  end

  desc "deleted", "refetch price for deleted books"
  def deleted
    logger.info "#{Time.now}: Updating deleted..."

    Updater.fetch_info(DB::Item.all(:deleted => true, :fields => [:asin]).collect { |item| item.asin })
  end

  desc "tweets", "sync tweets"
  def tweets
    logger.info "#{Time.now}: Get tweets..."

    Updater.fetch_tweets
  end

  desc "images", "sync asin images"
  def images
    logger.info "#{Time.now}: Get images..."

    Updater.fetch_images
  end

end

CLI.start(ARGV)

