# encoding: UTF-8

module FreeKindleCN

  class Updater
    class << self

      def fetch_price(asin)
        # mobile chrome
        client = HTTPClient.new :agent_name => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en-gb) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3"

        content = client.get("http://www.amazon.cn/gp/aw/d/#{asin}").content

        doc = Nokogiri::HTML(content, nil, 'UTF-8')

        begin
          if doc.css('p.infoText').text == '该商品目前无法进行购买'
            book_price = kindle_price = -1
          else
            book_price = doc.css('span.listPrice').last.content.sub('￥', '').strip.to_f
            kindle_price = doc.at_css('span.kindlePrice').content.sub('￥', '').strip.to_f

            book_price = (book_price * 100).to_i
            kindle_price = (kindle_price * 100).to_i
          end

          [ book_price, kindle_price ]
        rescue Exception
          puts content

          raise
        end
      end

      def fetch_info(asins)
        client = ASIN::Client.instance

        all = []

        if asins.respond_to?(:each)
          asins.each_slice(10) do |slice|
            all += lookup(client, slice)
          end
        else
          all += lookup(client, asins)
        end

        all
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