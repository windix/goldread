require '../freekindlecn'

include FreeKindleCN

# Only use when DB is upgraded
DataMapper.auto_upgrade!

DB::Item.each do |item|
  price = item.prices(:order => [:retrieved_at.desc]).first

  puts "#{item.asin}: #{price.book_price} / #{price.kindle_price}"

  item.update(
    :book_price => price.book_price,
    :kindle_price => price.kindle_price,
    :discount_rate => price.discount_rate,
    :updated_at => price.retrieved_at
  )
end

puts "Done!"