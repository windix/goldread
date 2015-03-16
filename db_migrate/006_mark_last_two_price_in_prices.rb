=begin

ALTER TABLE `prices`
ADD `orders` SMALLINT NOT NULL DEFAULT  '0',
CHANGE `retrieved_at` `retrieved_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

=end

require '../freekindlecn'

include FreeKindleCN

DB::Item.all.each do |item|
    prices = item.prices(:order => [:id.asc])

    prices.update(:orders => 0)

    if last = prices[-1]
      last.update(:orders => -1)
    end

    if second_last = prices[-2]
      second_last.update(:orders => -2)
    end
end

d "DONE!"
