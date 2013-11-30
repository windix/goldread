require "../freekindlecn"

gem "minitest"
require "minitest/autorun"

class TestParser < MiniTest::Test

  def test_for_deleted_asin
    # 领导力沉思录 http://goldread.net/admin/dp/B008H04RQS
    asin = "B008H04RQS"

    web_parser = FreeKindleCN::Parser::WebDetail.new asin
    assert_equal false, web_parser.parse
    assert_equal 404, web_parser.status_code
    assert_equal nil, web_parser.book_price
    assert_equal nil, web_parser.kindle_price

    mobile_parser = FreeKindleCN::Parser::MobileDetail.new asin
    assert_equal false, mobile_parser.parse
    assert_equal 200, mobile_parser.status_code
    assert_equal nil, mobile_parser.book_price
    assert_equal nil, mobile_parser.kindle_price
  end

  def test_for_normal_asin
    # 中国经济站在了十字路口? http://goldread.net/admin/dp/B00EADY1MQ
    asin = "B00EADY1MQ"

    web_parser = FreeKindleCN::Parser::WebDetail.new asin
    assert_equal true, web_parser.parse
    assert_equal 200, web_parser.status_code
    assert_equal 4200, web_parser.book_price
    assert_equal 499, web_parser.kindle_price

    mobile_parser = FreeKindleCN::Parser::MobileDetail.new asin
    assert_equal true, mobile_parser.parse
    assert_equal 200, mobile_parser.status_code
    assert_equal 4200, mobile_parser.book_price
    assert_equal 499, mobile_parser.kindle_price
  end

end
