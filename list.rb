# encoding: UTF-8

require 'httpclient'
require 'nokogiri'

class Array
  def odd_values
    self.values_at(* self.each_index.select(&:even?))
  end

  def even_values
    self.values_at(* self.each_index.select(&:odd?))
  end
end

class List
  def initialize
    @client = HTTPClient.new
  end

  # 销售飙升榜
  def movers_and_shakers
    all = []

    (1..5).each do |i|
      all += fetch_page("movers-and-shakers", i)
    end

    all
  end

  # 新品排行榜
  def new_releases
    all = []

    (1..5).each do |i|
      all += fetch_page("new-releases", i)
    end

    all
  end

  # 商品销售榜 (付费, 免费)
  def bestsellers
    all = []

    (1..5).each do |i|
      all += fetch_page("bestsellers", i)
    end

    [all.odd_values, all.even_values]
  end

  private

  def fetch_page(name, page)
    fetch(name, page, true) + fetch(name, page, false)
  end

  def fetch(name, page, above_the_fold)
    node = (name == "bestsellers") ? "116169071" : ""
    above_the_fold_param = above_the_fold ? "" : "&isAboveTheFold=0"

    url = "http://www.amazon.cn/gp/#{name}/digital-text/#{node}?ie=UTF8&pg=#{page}&ajax=1#{above_the_fold_param}"
    content = @client.get(url).content

    doc = Nokogiri::HTML(content, nil, 'UTF-8')

    #doc.css("span.asinReviewsSummary").collect { |span| span['name'] }
    doc.css("div.zg_title a").collect { |a| a.content }
  end

end


list = List.new

#p list.movers_and_shakers
#p list.new_releases
p list.bestsellers

