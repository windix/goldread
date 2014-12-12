require '../freekindlecn'

include FreeKindleCN

# Only use when DB is upgraded
DataMapper.auto_upgrade!

Updater.fetch_info(DB::Item.all(:fields => [:asin]).collect { |item| item.asin })

puts "Done!"