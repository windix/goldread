# encoding: UTF-8

module FreeKindleCN

  class Updater
    NUM_OF_THREADS_FETCHING_PRICE = 15
    # NUM_OF_THREADS_FETCHING_BINDINGS_AND_RATINGS = 5

    class << self

      def fetch_bindings_and_ratings(asin)
        asin_client = ASIN::Client.instance
        douban_client = Douban.client(DOUBAN_CONFIG)

        db_item = DB::Item.first(:asin => asin)

        unless db_item.bindings.empty?
          puts "[#{asin}] #{db_item.bindings.length} bindings exist, skip..."
          return
        else
          puts "[#{asin}] #{db_item.title}"
        end

        ### PARSE WEB PAGE

        content = HTTPClient.get_content("http://www.amazon.cn/dp/#{asin}")
        doc = Nokogiri::HTML(content, nil, 'UTF-8')

        bindings = doc.css('table.twisterMediaMatrix table tbody').collect { |t| t['id'] }.compact

        if bindings.empty?
          puts "[#{asin}] No other bindings, skip..."
          return
        end

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
            when "audiobooks_meta_binding_winner", "other_meta_binding_winner"
              # audiobook, skip
              next
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

          # invalid isbn13
          unless item.isbn13
            puts "ISBN for [#{book_asin}] is empty, skip..."
            next
          end

          begin
            book_info = douban_client.isbn(item.isbn13)
          rescue Douban::BadRequest
            # exceed Douban's request limits
            raise
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
      end

      def fetch_price(asin)
        # mobile chrome, 这个是可购买的手机版本页面
        client = HTTPClient.new :agent_name => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en-gb) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3"

        retry_times = 0
        begin
          content = client.get_content("http://www.amazon.cn/gp/aw/d/#{asin}")

          if content.encoding.to_s != "UTF-8"
            # log
            File.open("encoding_error_#{asin}.txt", "w") { |f| f.write(content) }
            content = content.force_encoding("UTF-8")

            # content.encode!("UTF-8", :invalid => :replace, :undef => :replace, :replace => '') # unless content.valid_encoding?
          end

          if content.include? "<h2>意外错误</h2>"
            # temporary error, retry
            raise "temporary error, retry"
          end

          doc = Nokogiri::HTML(content, nil, 'UTF-8')

          if doc.css('p.infoText').text == '该商品目前无法进行购买'
            # book is temporary unavailable
            book_price = kindle_price = -1

          elsif doc.css('input[name="ASIN.0"]').length == 1
            # book is available

            # listPrice有两个通常：电子书定价 / 纸书定价，一些情况下只有电子书定价
            book_price = doc.css('span.listPrice').last.content.sub('￥', '').strip.to_f
            kindle_price = doc.at_css('span.kindlePrice').content.sub('￥', '').strip.to_f

            book_price = (book_price * 100).to_i
            kindle_price = (kindle_price * 100).to_i

          else
            # book is permanently unavailable -- the ASIN becomes invalid
            # but we need to verify it: the web dp page will be 404 if it is PERMANENTLY unavailable
            return nil if HTTPClient.get("http://www.amazon.cn/dp/#{asin}").status_code == 404
          end
        rescue Exception => e
          puts e.backtrace

          retry_times += 1

          if retry_times > 3
            raise
          else
            puts "[#{retry_times}] Exception: #{$!}"
            puts content
            sleep 5
            retry
          end
        end

        [ book_price, kindle_price ]
      end

      def fetch_info(asins, to_fetch_price = true, to_fetch_bindings_and_ratings = true)
        # if passed one single ASIN convert it to array
        asins = [asins] unless asins.respond_to?(:each)

        db_items = []
        unloaded_asins = []

        asins.each do |asin|
          db_item = DB::Item.first(:asin => asin)

          if db_item
            # skip updating deleted item
            next if db_item.deleted

            db_items << db_item
          else
            unloaded_asins << asin
          end
        end

        if unloaded_asins.length > 0
          client = ASIN::Client.instance

          unloaded_asins.each_slice(10) do |slice|
            lookup(client, slice).each do |item|
              db_item = item.save
              db_items << db_item if db_item
            end
          end
        end

        if to_fetch_price
          db_items.each_slice(NUM_OF_THREADS_FETCHING_PRICE) do |slice|

            threads = []
            slice.each do |db_item|
              threads << Thread.new do
                begin
                  # TODO: also check timestamp
                  book_price, kindle_price = fetch_price(db_item.asin)

                  unless kindle_price
                    db_item.update(:deleted => true)
                    puts "[#{db_item.asin}] **** REMOVED ****"
                  else
                    if db_item.book_price != book_price ||
                      db_item.kindle_price != kindle_price ||
                      db_item.prices.empty?

                      discount_rate = (book_price != 0) ? kindle_price.to_f / book_price.to_f : 0.0
                      now = Time.now

                      if kindle_price != -1 && db_item.last_price != kindle_price
                        db_item.prices.create(
                          :kindle_price => kindle_price,
                          :retrieved_at => now
                        )
                      end

                      db_item.update(
                        :book_price => book_price,
                        :kindle_price => kindle_price,
                        :discount_rate => discount_rate,
                        :updated_at => now
                      )

                      puts "[#{db_item.asin}] #{db_item.author} - #{db_item.title}: #{kindle_price} / #{book_price}"
                    end

                    if to_fetch_bindings_and_ratings
                      begin
                        fetch_bindings_and_ratings(db_item.asin)
                      rescue => e
                        puts "(fetch bindings and ratings) Skip #{db_item.asin} because of Exception: #{e.message}"
                      end
                    end

                  end
                rescue => e
                  puts "(fetch price) Skip #{db_item.asin} because of Exception: #{e.message}"
                end
              end # Thread.new
            end # slice.each

            threads.each { |thread| thread.join }

          end # db_items.each_slice
        end

        # if to_fetch_bindings_and_ratings
        #   db_items.each_slice(NUM_OF_THREADS_FETCHING_BINDINGS_AND_RATINGS) do |slice|

        #     threads = []
        #     slice.each do |db_item|
        #       threads << Thread.new do
        #         begin
        #           fetch_bindings_and_ratings(db_item.asin)
        #         rescue => e
        #           puts "(fetch bindings and ratings) Skip #{db_item.asin} because of Exception: #{e.message}"
        #         end
        #       end # Thread.new
        #     end # slice.each

        #     threads.each { |thread| thread.join }

        #   end # db_items.each_slice
        # end

        db_items
      end

      private

      def lookup(client, asins)
        retry_times = 0

        begin
          client.lookup(asins)
        rescue Exception # => e
          retry_times += 1

          if retry_times > 3
            raise
          else
            puts "[#{retry_times}] Exception: #{$!}"
            sleep 5
            retry
          end
        end
      end

    end
  end
end
