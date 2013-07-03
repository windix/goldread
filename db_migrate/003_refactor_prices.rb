=begin

use goldread;

RENAME TABLE free_kindle_cn_db_items TO items;
RENAME TABLE free_kindle_cn_db_prices TO prices;

CREATE TABLE prices_new LIKE prices;

ruby 003_refactor_prices.rb | mysql -uroot -p***REMOVED*** goldread

--

ALTER TABLE prices_new
  DROP book_price,
  DROP discount_rate;

=end

require '../freekindlecn'

include FreeKindleCN

def output_sql(price)
  puts "INSERT INTO prices_new VALUES (NULL, #{price.book_price}, #{price.kindle_price}, #{price.discount_rate}, '#{price.retrieved_at.strftime(MYSQL_FORMAT)}', '#{price.item_id}', '#{price.item_asin}');"
end

DB::Item.all.each do |item|
  previous_price, price_to_keep = nil, nil

  prices = item.prices(:order => [:id.asc])

  prices.each do |price|
    unless previous_price
      price_to_keep = previous_price = price
      next
    end

    if price.kindle_price != previous_price.kindle_price
      output_sql(price_to_keep) if price_to_keep.kindle_price != -1
      price_to_keep = price
    end

    previous_price = price
  end

  output_sql(price_to_keep) if price_to_keep.kindle_price != -1
end
