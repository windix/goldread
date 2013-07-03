# encoding: UTF-8

module FreeKindleCN

  class Updater
    class << self

      def fetch_price(asin)
        # mobile chrome, 这个是可购买的手机版本页面
        client = HTTPClient.new :agent_name => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en-gb) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3"

        retry_times = 0
        begin
          content = client.get("http://www.amazon.cn/gp/aw/d/#{asin}").content

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
            puts content
            return nil
          end
        rescue Exception # => e
          raise
          # retry_times += 1

          # if retry_times > 3
          #   raise
          # else
          #   puts "[#{retry_times}] Exception: #{$!}"
          #   puts content
          #   sleep 5
          #   retry
          # end
        end

        [ book_price, kindle_price ]
      end

      def fetch_info(asins, to_fetch_price = true)
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
          db_items.each_slice(15) do |slice|

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
                    if (db_item.book_price != book_price || db_item.kindle_price != kindle_price)
                      discount_rate = (book_price != 0) ? kindle_price.to_f / book_price.to_f : 0.0
                      now = Time.now

                      db_item.update(
                        :book_price => book_price,
                        :kindle_price => kindle_price,
                        :discount_rate => discount_rate,
                        :updated_at => now
                      )

                      db_item.prices.create(
                        :kindle_price => kindle_price,
                        :retrieved_at => now
                      ) if (kindle_price != -1)

                      puts "[#{db_item.asin}] #{db_item.author} - #{db_item.title}: #{kindle_price} / #{book_price}"
                    end
                  end
                rescue Exception
                  puts "Skip #{db_item.asin} because of Exception: #{$!}"
                end
              end
            end # slice.each

            threads.each { |thread| thread.join }

          end # db_items.each_slice
        end

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
