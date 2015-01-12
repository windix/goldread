# encoding: UTF-8

module FreeKindleCN

  class Updater
    NUM_OF_THREADS_TO_FETCH_INFO = 15

    class << self

      def asin_client
        @asin_client ||= ASINHelper.new
      end

      def douban_client
        @douban_client ||= DoubanHelper.client
      end

      def fetch_bindings(db_item)
        if db_item.bindings.length == db_item.web_parser.bindings.length
          logger.debug "[#{db_item.asin}] no binding changes"
        else
          logger.info "[#{db_item.asin}] Parse bindings for #{db_item.title}"

          ### WEB PARSER: for bindings and amazon rating
          db_item.web_parser.bindings.each do |binding_type, book_asin|
            book_isbn = nil

            if binding_type != :kindle
              # skip douban lookup for kindle book

              ### AMAZON API, only for ISBN at moment
              item = asin_client.lookup_one(book_asin)

              unless item
                logger.debug "[#{db_item.asin}] Cannot find Book ASIN: #{book_asin}, skip..."
                next
              end

              book_isbn = item.isbn13

              ### DOUBAN API, for douban ID and douban rating
              book_info = DoubanHelper.lookup(item.isbn13)
            end

            unless db_item.bindings.first(:asin => book_asin)
              # SAVE TO DB
              logger.info "[#{db_item.asin}] #{binding_type}: #{book_asin}" + (book_isbn ? ", #{book_isbn}" : "")

              db_item.bindings.create(
                :type => binding_type.to_s,
                :asin => book_asin,
                :isbn => book_isbn,
                :douban_id => book_info ? book_info[:id] : nil,
                :preferred => (db_item.bindings.count(preferred: true) == 0 && binding_type != :kindle)
              )
            end
          end # end of bindings
        end
      rescue => e
        logger.error "[#{db_item.asin}] (fetch_bindings) Skip because of Exception: #{e.message}"
        logger.debug e.backtrace
      end

      def fetch_amazon_rating(db_item)
        # AMAZON RATING - same for different bindings of the same book
        average = db_item.web_parser.average_reviews
        num_of_votes = db_item.web_parser.num_of_votes

        db_item.ratings.first_or_create({
            :source => 'amazon'
          }, {
            :source => 'amazon',
            :average => average * 10,
            :num_of_votes => num_of_votes
          }
        ).save

        logger.info "[#{db_item.asin}] amazon rating: #{average} (#{num_of_votes})"
      rescue => e
        logger.error "[#{db_item.asin}] (fetch_amazon_rating) Skip because of Exception: #{e.message}"
        logger.debug e.backtrace
      end

      def fetch_douban_rating(db_item)
        # TEMPORARY: only fetch when douban rating does not exist
        return if db_item.ratings.first(:source => 'douban')

        perferred_binding = db_item.bindings.first(preferred: true)

        if (perferred_binding)
          ### DOUBAN API, for douban ID and douban rating
          book_info = DoubanHelper.lookup(perferred_binding.isbn)

          # DOUBAN RATING - same for different bindings of the same book
          if book_info && book_info[:rating]
            average = book_info[:rating][:average].to_f
            num_of_votes = book_info[:rating][:numRaters].to_i

            db_item.ratings.first_or_create({
                :source => 'douban',
              }, {
                :source => 'douban',
                :average => average * 10,
                :num_of_votes => num_of_votes
              }
            ).save

            logger.info "[#{db_item.asin}] douban rating: #{average} (#{num_of_votes})"
          end
        end
      rescue => e
        logger.error "[#{db_item.asin}] (fetch_douban_rating) Skip because of Exception: #{e.message}"
        logger.debug e.backtrace
      end

      def fetch_price(db_item)
        case db_item.mobile_parser.parse_result
        when Parser::Base::RESULT_DELETED
          db_item.update(:deleted => true)
          logger.info "[#{db_item.asin}] **** REMOVED ****"

        when Parser::Base::RESULT_FAILED
          logger.info "[#{db_item.asin}] **** SKIP - failed to fetch price ****"

        when Parser::Base::RESULT_SUCCESSFUL
          kindle_price = db_item.mobile_parser.kindle_price
          book_price = db_item.mobile_parser.book_price

          if kindle_price == -1
            logger.info "[#{db_item.asin}] **** SKIP - invalid kindle price ****"
          else
            db_item.deleted = false
            db_item.book_price = book_price if book_price != -1

            prices = db_item.prices(:order => [:id.asc])

            if db_item.kindle_price != kindle_price ||
              db_item.last_price != kindle_price ||
              prices.empty?

              logger.debug "[#{db_item.asin}] UPDATE PRICE #{db_item.kindle_price} -> #{kindle_price}"

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
          end
        end # case
      rescue => e
        logger.error "[#{db_item.asin}] (fetch_price) Skip because of Exception: #{e.message}"
        logger.debug e.backtrace
      end

      def fetch_info(asins)
        # if passed one single ASIN convert it to array
        asins = [asins] unless asins.respond_to?(:each)

        asins.each { |asin| Worker::FetchWorker.perform_async asin }
      end

      def fetch_info_old(asins)
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

        db_items.each_slice(NUM_OF_THREADS_TO_FETCH_INFO) do |slice|
          threads = []
          slice.each do |db_item|
            threads << Thread.new do

              fetch_price(db_item)

              fetch_bindings(db_item)

              fetch_amazon_rating(db_item)

              fetch_douban_rating(db_item)

            end # Thread.new
          end # slice.each

          threads.each { |thread| thread.join }
        end # db_items.each_slice

        db_items
      end

      def fetch_tweets
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
