# encoding: UTF-8

require 'bundler/setup'
require 'nokogiri'
require 'open-uri'

asin = 'B009P4OVLQ'

doc = Nokogiri::HTML(open("http://www.amazon.cn/dp/#{asin}"))

versions = doc.css('table.twisterMediaMatrix table tbody').collect { |t| t['id'] }.compact

versions.each do |version|
	tbody = doc.at_css("tbody##{version}")

	next if tbody.content.strip.empty?

	puts "----- #{version}"

	puts "版本：" + tbody.at_css('td.tmm_bookTitle').text.strip
	puts "价格：" + tbody.at_css('td.price').text.strip

	book_url = tbody.at_css('td.tmm_bookTitle a')

	puts "asin：" + book_url['href'][/dp\/([A-Z0-9]+)$/, 1] if book_url
	puts
end

puts "评价：" + doc.at_css('table#productDetailsTable span.crAvgStars span.swSprite').content
puts doc.at_css('table#productDetailsTable span.crAvgStars > a').content

puts "排名：" + doc.at_css('li#SalesRank').content[/Kindle商店商品里排第([\d,]+)名/, 1]
puts

doc.css('li#SalesRank ul li').each do |li|
	puts li.at_css('span.zg_hrsr_rank').content
	p li.css('span.zg_hrsr_ladder a').collect { |l| l.content }
end

puts
p doc.css('table#productDetailsTable div.content li')[0..6].collect { |li| li.content }

