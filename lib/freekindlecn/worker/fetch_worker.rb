require 'sidekiq'

module FreeKindleCN
  module Worker
    class FetchWorker
      include Sidekiq::Worker

      def perform(asin)
        db_item = DB::Item.first(:asin => asin)

        unless db_item
          asin_lookup_results = Updater.asin_client.lookup(asin)

          if asin_lookup_results.length > 0
            db_item = asin_lookup_results.first.save
          end
        end

        if db_item
          Updater.fetch_price(db_item)

          Updater.fetch_bindings(db_item)

          Updater.fetch_amazon_rating(db_item)

          Updater.fetch_douban_rating(db_item)
        end
      end

    end
  end
end