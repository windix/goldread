# encoding: UTF-8

=begin

CREATE TABLE IF NOT EXISTS `bindings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(10) DEFAULT NULL,
  `asin` varchar(10) DEFAULT NULL,
  `isbn` varchar(13) DEFAULT NULL,
  `douban_id` int(11) DEFAULT NULL,
  `preferred` tinyint(1) DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `item_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_bindings_item` (`item_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

CREATE TABLE IF NOT EXISTS `ratings` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `source` varchar(10) DEFAULT NULL,
  `average` int(11) DEFAULT NULL,
  `num_of_votes` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `item_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_rankings_item` (`item_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

=end

require '../freekindlecn'

include FreeKindleCN

asin_client = ASIN::Client.instance
douban_client = Douban.client(DOUBAN_CONFIG)

DB::Item.all(:deleted => false).each do |db_item|
  asin = db_item.asin

  unless db_item.bindings.empty?
    puts "[#{asin}] #{db_item.bindings.length} bindings exist, skip..."
    next
  else
    puts "[#{asin}] #{db_item.title}"
  end

  ### PARSE WEB PAGE

  content = HTTPClient.get_content("http://www.amazon.cn/dp/#{asin}")
  doc = Nokogiri::HTML(content, nil, 'UTF-8')

  bindings = doc.css('table.twisterMediaMatrix table tbody').collect { |t| t['id'] }.compact

  is_preferred = true
  bindings.each do |binding|
    tbody = doc.at_css("tbody##{binding}")
    next if tbody.content.strip.empty?

    binding_type = case binding
      when "paperback_meta_binding_winner"
        "paperback"
      when "hardcover_meta_binding_winner"
        "hardcover"
      when "kindle_meta_binding_winner", "kindle_meta_binding_body"
        "kindle"
      else
        puts "Unknown binding '#{binding}', skip...."
        next
      end

    book_url = tbody.at_css('td.tmm_bookTitle a')

    if book_url
      book_asin = book_url['href'][/dp\/([A-Z0-9]+)$/, 1]
    else
      puts "Cannot parse ASIN, skip..." if binding_type != "kindle"
      next
    end

    # "平均4.5 星"" -> 4.5
    average_reviews = doc.at_css('table#productDetailsTable span.crAvgStars span.swSprite').content[/[\d\.]+/].to_f

    # "56 条商品评论" => 56
    num_of_votes = doc.at_css('table#productDetailsTable span.crAvgStars > a').content[/[\d,]+/].sub(',', '').to_i


    ### AMAZON API

    items = asin_client.lookup(book_asin)

    if items.empty?
      puts "Cannot find Book ASIN: #{book_asin}, skip..." unless binding_type == "kindle"
      next
    else
      item = items.first
    end


    ### DOUBAN API

    begin
      book_info = douban_client.isbn(item.isbn13)
    rescue => e
      puts "Failed to find ISBN '#{item.isbn13}' from douban: #{e.message}, skip..."
      next
    end

    ### SAVE TO DB

    puts "[#{asin}] #{binding_type}#{is_preferred ? "*" : ""}: "\
      "#{book_asin}, #{item.isbn13}, "\
      "a: #{average_reviews} of #{num_of_votes}, "\
      "d: #{book_info[:rating][:average]} of #{book_info[:rating][:numRaters]}"

    # BINDING
    db_item.bindings.create(
      :type => binding_type,
      :asin => book_asin,
      :isbn => item.isbn13,
      :douban_id => book_info[:id],
      :preferred => binding_type == "kindle" ? false : is_preferred,
      :created_at => Time.now
    )

    if binding_type != "kindle" && is_preferred
      # AMAZON RATING
      db_item.ratings.create(
        :source => 'amazon',
        :average => average_reviews * 10,
        :num_of_votes => num_of_votes,
        :updated_at => Time.now
      )

      # DOUBAN RATING
      db_item.ratings.create(
        :source => 'douban',
        :average => book_info[:rating][:average].to_f * 10,
        :num_of_votes => book_info[:rating][:numRaters].to_i,
        :updated_at => Time.now
      )

      is_preferred = false
    end

  end # of bindings
end # of asins

