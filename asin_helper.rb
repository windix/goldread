class ASINHelper
  include ASIN::Client

  alias_method :old_handle_type, :handle_type

  def handle_type(data, type)
    FreeKindleCN::Item.new old_handle_type(data, type)
  end
end