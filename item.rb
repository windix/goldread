# encoding: UTF-8

require 'httpclient'
require 'nokogiri'

def get_price(asin)
  client = HTTPClient.new :agent_name => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en-gb) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3"

  content = client.get("http://www.amazon.cn/gp/aw/d/#{asin}").content

  doc = Nokogiri::HTML(content, nil, 'UTF-8')

  book_price = doc.css('span.listPrice').last.content.sub('￥', '').strip.to_f
  kindle_price = doc.at_css('span.kindlePrice').content.sub('￥', '').strip.to_f

  [ book_price, kindle_price ]
end

#p get_price('B009ZQB8VA')
#p get_price('B008HKBLTE')
#p get_price('B00D7YRXPG')
p get_price('B009Z5TEDK')
