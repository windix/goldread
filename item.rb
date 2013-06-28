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

    def save
      db_item = DB::Item.first_or_create({:asin => asin},
        {:book_price => -1,
          :kindle_price => -1,
          :discount_rate => 1,
          :created_at => Time.now})

      # we don't update price information when calling from fetch_info
      db_item.update(
        :title => title,
        :details_url => details_url,
        :review => review,
        :image_url => image_url,
        :thumb_url => thumb_url,
        :author => author,
        :publisher => publisher,
        :num_of_pages => num_of_pages,
        :publication_date => publication_date,
        :release_date => release_date,
        :updated_at => Time.now
      )

      db_item
    rescue Exception
      puts "Skip saving because of Exception: #{$!}"
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
      def is_valid_asin?(asin)
        asin =~ /^B[A-Z0-9]{9}$/
      end
    end

  end
end
