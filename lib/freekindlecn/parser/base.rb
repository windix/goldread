module FreeKindleCN
  module Parser

    class << self
      def factory(name, asin)
        parser = case name
                when 'mobile' then MobileDetail.new(asin)
                when 'web' then WebDetail.new(asin)
                else raise "Invalid Parser Name!"
                end

        parser.parse

        parser
      end
    end

    class Base

      RESULT_FAILED = 0      # failed to parse (due to network issue, temporarily)
      RESULT_SUCCESSFUL = 1  # successful
      RESULT_DELETED = 2     # book has been deleted

      attr_reader :asin, :content, :parse_result, :status_code

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

          @status_code = resp.status_code

          case(@status_code)
          when 200
            @parse_result = RESULT_SUCCESSFUL
            @content = resp.content
          when 404, 302
            # when using mobile mode, deleted book returns 302
            @parse_result = RESULT_DELETED
            return false
          else
            @parse_result = RESULT_FAILED
            raise "HTTP code: #{resp.status_code}"
          end

          doc = Nokogiri::HTML(@content, nil, 'UTF-8')

          yield doc
        rescue => e
          # logger.error e.backtrace
          retry_times += 1

          if retry_times > 3
            false
          else
            logger.debug "[#{@asin}] retry no.#{retry_times} Exception: #{e.message}"
            sleep 5
            retry
          end
        end
      end

      def asin_from_url(url)      
        formats = [
          %r{/gp/product/([A-Z0-9]+)}, # format1: /gp/product/{asin}/
          %r{/dp/([A-Z0-9]+)}          # format2: /dp/{asin}/
        ]

        formats.each { |format| return $~[1] if format.match url }

        nil # no match
      end

      # parse prices: used by web_detail and mobile_detail parser
      def parse_price_block(trs)
        @ebook_full_price = -1      # 电子书定价
        @paperbook_full_price = -1  # 纸书定价
        @paperbook_price = -1       # 纸书特价
        @kindle_price = -1          # 电子书特价

        @book_price = -1            # 图书价格 -- 派生自前三者

        trs.each do |tr|
          tds = tr.css('td')

          price = parse_price(tds[1].text[/￥\s([\d\.]+)/, 1])

          case tds[0].text.strip
          when /电子书定价/
            @ebook_full_price = price
          when /纸书定价/
            @paperbook_full_price = price
          when /Kindle电子书价格/
            @kindle_price = price
          when /价格/ # when parsing paperbook asin
            @paperbook_price = price
          when /为您节省/
            # skip
          else
            logger.error "parse_price_block: unknown price tag '#{tds[0].text.strip}', price=#{price}"
          end
        end

        # listPrice有两个通常：电子书定价 / 纸书定价，一些情况下只有电子书定价，也有时候没有
        if @paperbook_full_price != -1
          @book_price = @paperbook_full_price
        elsif @ebook_full_price != -1
          @book_price = @ebook_full_price
        else
          @book_price = 0
        end
      end

    end # class

  end
end