# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'asin'
require 'httpclient'

url = "http://www.amazon.cn/gp/feature.html/ref=amb_link_30648212_2?ie=UTF8&docId=126758&pf_rd_m=A1AJ19PSB66TGU&pf_rd_s=right-top&pf_rd_t=101&pf_rd_p=70106812&pf_rd_i=116169071"

doc = Nokogiri::HTML(open(url), nil, 'UTF-8')

price = doc.at_css('span.price').content
asin = doc.at_css('img[alt="立即购买"]').parent['href'].split('/').last

ASIN::Configuration.configure do |config|
  config.secret        = '***REMOVED***'
  config.key           = '***REMOVED***'
  config.associate_tag = '***REMOVED***'
  config.host          = 'webservices.amazon.cn'
end

include ASIN::Client
item = lookup(asin).first

puts item.title
puts item.details_url
puts price
puts item.image_url


