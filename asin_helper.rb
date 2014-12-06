class ASINHelper
  include ASIN::Client

  alias_method :old_handle_type, :handle_type

  alias_method :old_lookup, :lookup

  def handle_type(data, type)
    FreeKindleCN::Item.new old_handle_type(data, type)
  end

  def lookup(*asins)
    retry_times = 0

    begin
      old_lookup(asins)
    rescue Exception # => e
      retry_times += 1

      if retry_times > 3
        raise
      else
        logger.error "[#{retry_times}] Exception: #{$!}"
        sleep 5
        retry
      end
    end
  end

end