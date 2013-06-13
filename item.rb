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

    def author
      @raw.ItemAttributes!.Author
    end

    def publisher
      @raw.ItemAttributes!.Publisher
    end

    def review
      reviews = @raw.EditorialReviews!.EditorialReview!

      if reviews.is_a?(Array)
        reviews.first.Content
      else
        reviews.Content
      end
    end

    def num_of_pages
      @raw.ItemAttributes!.NumberOfPages
    end

    def publication_date
      @raw.ItemAttributes!.PublicationDate
    end

    def release_date
      @raw.ItemAttributes!.ReleaseDate
    end

    private

    def load_price
      @book_price, @kindle_price = self.class.fetch_price(asin)
    end

    class << self
      def fetch_price(asin)
        # mobile chrome
        client = HTTPClient.new :agent_name => "Mozilla/5.0 (iPhone; U; CPU iPhone OS 5_1_1 like Mac OS X; en-gb) AppleWebKit/534.46.0 (KHTML, like Gecko) CriOS/19.0.1084.60 Mobile/9B206 Safari/7534.48.3"

        content = client.get("http://www.amazon.cn/gp/aw/d/#{asin}").content

        doc = Nokogiri::HTML(content, nil, 'UTF-8')

        book_price = doc.css('span.listPrice').last.content.sub('￥', '').strip.to_f
        kindle_price = doc.at_css('span.kindlePrice').content.sub('￥', '').strip.to_f

        [ book_price, kindle_price ]
      end

      def fetch_info(asins)
        client = ASIN::Client.instance

        all = []

        if asins.respond_to?(:each)
          asins.each_slice(10) do |slice|
            all += client.lookup(slice)
          end
        else
          all += client.lookup(asins)
        end

        all
      end
    end    

  end
end
