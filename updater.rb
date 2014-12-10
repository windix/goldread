# encoding: UTF-8

module FreeKindleCN

  class Updater
    NUM_OF_THREADS_FETCHING_PRICE = 15
    # NUM_OF_THREADS_FETCHING_BINDINGS_AND_RATINGS = 5

    class << self

      def asin_client
        @asin_client ||= ASINHelper.new
      end

      def fetch_bindings_and_ratings(asin)
        douban_client = DoubanHelper.client

        db_item = DB::Item.first(:asin => asin)

        unless db_item.bindings.empty?
          logger.debug "[#{asin}] #{db_item.bindings.length} bindings exist, skip..."
          return
        else
          logger.debug "[#{asin}] #{db_item.title}"
        end

        ### PARSE WEB PAGE
        parser = Parser::WebDetail.new(asin)
        parser.parse

        is_preferred = true
        parser.bindings.each do |binding_type, book_asin|
          ### AMAZON API

          items = asin_client.lookup(book_asin)

          if items.empty?
            logger.debug "Cannot find Book ASIN: #{book_asin}, skip..." unless binding_type == :kindle
            next
          else
            item = items.first
          end

          ### DOUBAN API

          # invalid isbn13
          unless item.isbn13
            logger.debug "ISBN for [#{book_asin}] is empty, skip..."
            next
          end

          begin
            book_info = douban_client.isbn(item.isbn13)

          rescue Douban::Error => e
            if e.code == 6000
              # book_not_found
              logger.info "[#{book_asin}] Book not found in douban"
              next

            elsif e.code == 106
              # access_token_has_expired
              DoubanHelper.refresh_client
              logger.info "Douban token has been refreshed"
              retry

            else
              raise
            end
          end

          ### SAVE TO DB

          logger.info "[#{asin}] #{binding_type}#{is_preferred ? "*" : ""}: "\
            "#{book_asin}, #{item.isbn13}, "\
            "a: #{parser.average_reviews} of #{parser.num_of_votes}, "\
            "d: #{book_info[:rating][:average]} of #{book_info[:rating][:numRaters]}"

          # BINDING
          db_item.bindings.create(
            :type => binding_type.to_s,
            :asin => book_asin,
            :isbn => item.isbn13,
            :douban_id => book_info[:id],
            :preferred => binding_type == :kindle ? false : is_preferred,
            :created_at => Time.now
          )

          if binding_type != :kindle && is_preferred
            # AMAZON RATING
            db_item.ratings.create(
              :source => 'amazon',
              :average => parser.average_reviews * 10,
              :num_of_votes => parser.num_of_votes,
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
        parser = Parser::MobileDetail.new(asin)
        parser.parse

        #[ parser.book_price, parser.kindle_price ]

        parser
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
            # next if db_item.deleted

            db_items << db_item
          else
            unloaded_asins << asin
          end
        end

        if unloaded_asins.length > 0
          unloaded_asins.each_slice(10) do |slice|
            asin_client.lookup(slice).each do |item|
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
                  parser = fetch_price(db_item.asin)

                  case parser.parse_result
                  when Parser::Base::RESULT_DELETED
                    db_item.update(:deleted => true)
                    logger.info "[#{db_item.asin}] **** REMOVED ****"

                  when Parser::Base::RESULT_FAILED
                    logger.info "[#{db_item.asin}] **** SKIP - failed to fetch price ****"

                  when Parser::Base::RESULT_SUCCESSFUL
                    kindle_price = parser.kindle_price
                    book_price = parser.book_price

                    if kindle_price == -1
                      logger.info "[#{db_item.asin}] **** SKIP - invalid kindle price ****"
                    else
                      db_item.deleted = false
                      db_item.book_price = book_price if book_price != -1

                      prices = db_item.prices(:order => [:id.asc])

                      if db_item.kindle_price != kindle_price ||
                        db_item.last_price != kindle_price ||
                        prices.empty?

                        logger.info "[#{db_item.asin}] UPDATE PRICE #{db_item.kindle_price} -> #{kindle_price}"

                        # save new price
                        now = Time.now

                        if db_item.last_price != kindle_price
                          unless prices.empty?
                            last_prices_id = prices[-1].id

                            # first clear orders for existing prices
                            #prices.update(:orders => 0) unless prices.length == 1
                            DB::Price.all(:item_id => db_item.id).update(:orders => 0) unless prices.length == 1

                            # only need to mark the second last -- since the new entry will be the last one
                            DB::Price.first(:id => last_prices_id).update(:orders => -2)
                          end

                          db_item.prices.create(
                            :kindle_price => kindle_price,
                            :retrieved_at => now,
                            :orders => -1
                          )
                        end

                        db_item.kindle_price = kindle_price

                        # only update updated_at when kindle price changed
                        db_item.updated_at = now

                      else
                        # price is unchanged
                      end

                      # save to DB if anything changed
                      unless db_item.clean?
                        db_item.discount_rate = (book_price != 0) ? kindle_price.to_f / book_price.to_f : 0.0
                        db_item.save

                        logger.info "[#{db_item.asin}] #{db_item.author} - #{db_item.title}: #{kindle_price} / #{book_price}"
                      end

                      if to_fetch_bindings_and_ratings
                        begin
                          fetch_bindings_and_ratings(db_item.asin)
                        rescue => e
                          logger.error e.backtrace
                          logger.error "(fetch bindings and ratings) Skip #{db_item.asin} because of Exception: #{e.message}"
                        end
                      end

                    end
                  end

                rescue => e
                  logger.error e.backtrace
                  logger.error "(fetch price) Skip #{db_item.asin} because of Exception: #{e.message}"
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
        #           logger.error "(fetch bindings and ratings) Skip #{db_item.asin} because of Exception: #{e.message}"
        #         end
        #       end # Thread.new
        #     end # slice.each

        #     threads.each { |thread| thread.join }

        #   end # db_items.each_slice
        # end

        db_items
      end

      def fetch_tweets
        require 'twitter_config'

        tweets = Twitter.user_timeline(TWITTER_ACCOUNT,
          :count => 100,
          :exclude_replies => true,
          :trim_user => true,
          :contributor_details => false,
          :include_rts => false,
          :since_id => DB::TweetArchive.first(:order => [:published_at.desc]).tweet_id
        )

        tweets.reverse.each do |t|
          hashtag = t.hashtags.first

          if hashtag && (hashtag.text == "Kindle好书推荐" || hashtag.text == "Kindle今日特价书")
            content = CGI.unescape(t.text)

            next if t.urls.empty?

            # store full URLs
            t.urls.each { |url| content.sub!(url.url, url.expanded_url) }

            # remove image URL
            t.media.each { |media| content.sub!(media.url, '') }

            is_main = true
            t.urls.each do |url|
              asin = url.expanded_url[/dp\/([A-Z0-9]+)/, 1]
              next unless asin

              item = DB::Item.first(:asin => asin)

              d "#{t.id}, #{hashtag.text}, #{t.created_at} [#{asin}]"
              d content

              DB::TweetArchive.create(
                :tweet_id => t.id,
                :published_at => t.created_at,
                :content => content[0...300],
                :hashtag => hashtag.text,
                :is_main => is_main,
                :item_id => item.id
              )

              is_main = false
            end
          end
        end
      end

      NO_IMAGE_PLACE_HOLDER = "http://g-ec4.images-amazon.com/images/G/28/x-site/icons/no-img-sm._V192562228_.gif"

      def fetch_images
        DB::Item.all.each do |item|
          next if item.image_url == NO_IMAGE_PLACE_HOLDER

          unless File.exists? "#{FreeKindleCN::BOOK_IMAGE_CACHE_PATH}/#{item.asin}.jpg"
            puts "wget #{item.image_url} -O #{FreeKindleCN::BOOK_IMAGE_CACHE_PATH}/#{item.asin}.jpg"
          end
        end
      end

    end
  end
end
