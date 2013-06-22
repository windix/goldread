# encoding: UTF-8

module FreeKindleCN
  class Item < ASIN::SimpleItem

    # asin, title, details_url, review, image_url

    def book_price
      load_price unless @book_price

      @book_price
    end

    def kindle_price
      load_price unless @kindle_price

      @kindle_price
    end

    # get author using the following orders:
    # - use Author (or CSV when it is an array)
    # - use Creator (or CSV when it is an array)
    # - empty string
    def author
      unless @author
        @author = convert_content(@raw.ItemAttributes!.Author)

        unless @author
          @author = convert_content(@raw.ItemAttributes!.Creator)
          unless @author
            @author = ""
          end
        end
      end

      @author
    end

    def publisher
      @raw.ItemAttributes!.Publisher
    end

    def review
      convert_content(@raw.EditorialReviews!.EditorialReview!, true).Content
    end

    def num_of_pages
      @raw.ItemAttributes!.NumberOfPages.to_i
    end

    def publication_date
      @raw.ItemAttributes!.PublicationDate
    end

    def release_date
      @raw.ItemAttributes!.ReleaseDate
    end

    def save
      puts "[#{asin}] #{author} - #{title}: #{kindle_price} / #{book_price}"

      db_item = DB::Item.first_or_create({:asin => asin},
        {:created_at => Time.now})

      db_item.update({
        :title => title,
        :details_url => details_url,
        :review => review,
        :image_url => image_url,
        #:thumb_url
        :author => author,
        :publisher => publisher,
        :num_of_pages => num_of_pages,
        :publication_date => publication_date,
        :release_date => release_date,
        :updated_at => Time.now})

      if (db_item.book_price != book_price || db_item.kindle_price != kindle_price)
        db_item.prices.create({
          :book_price => book_price,
          :kindle_price => kindle_price,
          :discount_rate => (book_price != 0) ? kindle_price.to_f / book_price.to_f : 0.0,
          :retrieved_at => Time.now})
      end
    rescue Exception
      puts "Skip saving because of Exception: #{$!}"
      # ignore
    end

    private

    def load_price
      @book_price, @kindle_price = self.class.fetch_price(asin)
    end

    # when content is an array, return first element or CSV string
    def convert_content(content, array_get_first_element = false)
      if content.is_a?(Array)
        if array_get_first_element
          content.first
        else
          content.join(",")
        end
      else
        content
      end
    end

    class << self
      def is_valid_asin?(asin)
        asin =~ /^B[A-Z0-9]{9}$/
      end

      def fetch_price(asin)
        # mobile chrome
        client = HTTPClient.new :agent_name => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en-gb) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3"

        content = client.get("http://www.amazon.cn/gp/aw/d/#{asin}").content

        doc = Nokogiri::HTML(content, nil, 'UTF-8')

        begin
          book_price = doc.css('span.listPrice').last.content.sub('￥', '').strip.to_f
          kindle_price = doc.at_css('span.kindlePrice').content.sub('￥', '').strip.to_f

          book_price = (book_price * 100).to_i
          kindle_price = (kindle_price * 100).to_i

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
