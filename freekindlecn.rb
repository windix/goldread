# encoding: UTF-8

require 'bundler/setup'
require 'asin'
require 'httpclient'
require 'nokogiri'

require './list'
require './item'
require './asin_config'
require './db'

module FreeKindleCN

  list = AsinList.new

=begin
  asins = list.new_releases

  items = Item.fetch_info asins[0]

  puts items.first.kindle_price
=end

  #Item.fetch_info(list.daily_deal).each do |item|
  Item.fetch_info(list.new_releases).each do |item|
    puts item.asin
    puts item.title
    puts item.author
    puts item.details_url
    puts item.review
    puts item.image_url
    puts item.num_of_pages
    puts item.publication_date
    puts item.release_date
    puts item.book_price
    puts item.kindle_price

    puts "---------------------"
  end



end