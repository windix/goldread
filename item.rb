# encoding: UTF-8

module FreeKindleCN
  class Item < ASIN::SimpleItem

    # asin, title, details_url, review, image_url

    def thumb_url
      @raw.MediumImage!.URL
    end

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
      @author ||=
        convert_content(@raw.ItemAttributes!.Author) ||
        convert_content(@raw.ItemAttributes!.Creator) ||
        ""
    end

    def publisher
      @raw.ItemAttributes!.Publisher.to_s
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

    def binding
      case @raw.ItemAttributes!.binding
      when "平装"
        "paperback"
      when "Kindle版"
        "kindle"
      when "精装"
        "hardcover"
      else
        # other known bindings: "CD"
        nil
      end
    end

    def isbn13
      # only keep first 13 digits
      # e.g. for B008H0H9FO, the EAN is 9787510407550 01
      @raw.ItemAttributes!.EAN[0..12] rescue nil
    end

    def save
      now = Time.now

      DB::Item.first_or_create({:asin => asin},
        {:title => title,
        :details_url => details_url,
        :review => review,
        :image_url => image_url,
        :thumb_url => thumb_url,
        :author => author,
        :publisher => publisher,
        :num_of_pages => num_of_pages,
        :publication_date => publication_date,
        :release_date => release_date,
        :book_price => -1,
        :kindle_price => -1,
        :discount_rate => 1.0,
        :created_at => now,
        :updated_at => now}
      )
    rescue => e
      d "Skip saving because of Exception: #{e.message}"
      nil
    end

    private

    def load_price
      @book_price, @kindle_price = Updater.fetch_price(asin)
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
      # this is probably wrong in some case for paper book (some even uses ISBN directly)
      def is_valid_asin?(asin)
        asin =~ /^B[A-Z0-9]{9}$/
      end

      def douban_api_url(douban_id)
        "http://api.douban.com/v2/book/#{douban_id}"
      end

      def douban_page_url(douban_id)
        "http://book.douban.com/subject/#{douban_id}/"
      end

      def amazon_url(asin)
        "http://www.amazon.cn/dp/#{asin}"
      end

      def formatted_discount_rate(discount_rate)
        "%.1f折" % (discount_rate.to_f * 10)
      end

      def formatted_rating(average, num_of_votes)
        "#{average.to_f / 10} (#{num_of_votes})"
      end

    end

  end
end
