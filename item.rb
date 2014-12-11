# encoding: UTF-8
module FreeKindleCN
  class Item

    def initialize(subject)
      @subject = subject
    end

    # asin, title, amount, details_url, review*, image_url, author*,
    # binding*, brand, ean, edition, isbn, 
    # item_dimensions, item_height, item_length, item_width, item_weight,
    # package_dimensions, package_height, package_length, package_width, package_weight,
    # label, language, formatted_price, manufacturer, mpn, 
    # page_count*, part_number, product_group, publication_date, publisher*,
    # sku, studio, total_new, total_used

    def method_missing(sym, *args, &block)
      @subject.send sym, *args, &block
    end

    def thumb_url
      medium_image!.url
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
        convert_content(item_attributes!.author) ||
        convert_content(item_attributes!.creator) ||
        ""
    end

    def review
      convert_content(editorial_reviews!.editorial_review!, true).content
    end

    def publisher
      # have to prefix @subject to avoid loop
      @subject.publisher.to_s
    end

    def num_of_pages
      page_count.to_i
    end

    def release_date
      item_attributes!.release_date
    end

    def binding
      case item_attributes!.binding
      when "平装"
        "paperback"
      when "Kindle版"
      when "Kindle电子书"
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
      isbn = ean[0..12] rescue nil
      self.class.is_valid_isbn?(isbn) ? isbn : nil
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
      parser = Updater.fetch_price(asin)

      if parser.parse_result == FreeKindleCN::Parser::Base::RESULT_SUCCESSFUL
        @kindle_price = parser.kindle_price
        @book_price = parser.book_price
      end
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

      def is_valid_isbn?(isbn)
        isbn =~ /^\d+$/
      end

      def douban_api_url(douban_id)
        douban_id ? "http://api.douban.com/v2/book/#{douban_id}" : "#"
      end

      def douban_page_url(douban_id)
        douban_id ? "http://book.douban.com/subject/#{douban_id}/" : "#"
      end

      def amazon_url(asin)
        asin ? "http://www.amazon.cn/dp/#{asin}" : "#"
      end

      def formatted_discount_rate(discount_rate)
        "%.1f折" % (discount_rate.to_f * 10)
      end

      def formatted_rating(average, num_of_votes)
        "#{average.to_f / 10} (#{num_of_votes})" if (average && num_of_votes)
      end

    end

  end
end
