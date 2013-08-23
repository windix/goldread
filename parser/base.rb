# encoding: UTF-8

module FreeKindleCN
  module Parser

    class Base
      attr_reader :asin, :content

      def initialize(asin)
        @asin = asin
      end

      protected

      def client(mobile)
        if mobile
          user_agent = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en-gb) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3"
        else
          user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.55 Safari/537.36"
        end

        HTTPClient.new :agent_name => user_agent
      end

      def convert_to_cents(price)
        (price * 100).to_i
      end

      def parse_price(s)
        convert_to_cents(s.sub('￥', '').strip.to_f)
      end

      def parse_with_retry(url, mobile = false)
        retry_times = 0
        begin
          resp = client(mobile).get(url)

          case(resp.status_code)
          when 200
            @content = resp.content
          when 404
            return false
          else
            raise "HTTP code: #{resp.status_code}"
          end

          doc = Nokogiri::HTML(@content, nil, 'UTF-8')

          yield doc
        rescue => e
          logger.error e.backtrace

          retry_times += 1

          if retry_times > 3
            false
          else
            logger.error "[#{retry_times}] Exception: #{e.message}"
            logger.debug @content
            sleep 5
            retry
          end
        end
      end

    end # class

  end
end