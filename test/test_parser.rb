require_relative "../bootstrap"
require 'minitest/autorun'
require 'webmock/minitest'
require 'yaml'

class TestParser < MiniTest::Test

  include FreeKindleCN::Parser

  def test_web_daily_deals
    loop_through_fixtures('web_daily_deals') do
      parser = WebDailyDeals.new

      assert_equal true, parser.parse

      refute_empty parser.daily_asins
      refute_empty parser.weekly_asins

      (parser.daily_asins + parser.weekly_asins).each { |asin| assert_match /^[A-Z0-9]+$/, asin, "invalid asin" }
    end
  end

  def test_web_list
    # WebList.url_for('bestsellers')

    loop_through_fixtures('web_list') do |file_name|
      parser = WebList.new('bestsellers')

      assert_equal true, parser.parse

      refute_empty parser.asins
      refute_empty parser.titles
      refute_empty parser.prices

      parser.asins.each { |asin| assert_match /^[A-Z0-9]+$/, asin, "invalid asin" }
    end
  end

  def test_web_details
    loop_through_fixtures('web_detail') do |file_path|
      parser = FreeKindleCN::Parser.factory('web', 'ASIN')

      assert_equal WebDetail::RESULT_SUCCESSFUL, parser.parse_result, 'parse_result'

      # verify against data file
      YAML.load_file("#{file_path}.yaml").each do |k, v|
        assert_equal v, parser.send(k), k.to_s
      end
    end
  end

  protected

  def loop_through_fixtures(name, &block)
    WebMock.enable!
    Dir[__dir__ + "/fixture/#{name}/*html"].each do |file_path|
      # logger.debug file_path

      WebMock.reset!

      stub_request(:any, %r[www.amazon.cn/.*]).to_return(
        :body => File.open(file_path)
      )

      block.call file_path
    end

    # check with live page
    # WebMock.disable!
    # block.call
  end


  # def test_for_deleted_asin
  #   # 领导力沉思录 http://goldread.net/admin/dp/B008H04RQS
  #   asin = "B008H04RQS"

  #   web_parser = FreeKindleCN::Parser::WebDetail.new asin
  #   assert_equal false, web_parser.parse
  #   assert_equal 404, web_parser.status_code
  #   assert_equal nil, web_parser.book_price
  #   assert_equal nil, web_parser.kindle_price

  #   mobile_parser = FreeKindleCN::Parser::MobileDetail.new asin
  #   assert_equal false, mobile_parser.parse
  #   assert_equal 200, mobile_parser.status_code
  #   assert_equal nil, mobile_parser.book_price
  #   assert_equal nil, mobile_parser.kindle_price
  # end

  # def test_for_normal_asin
  #   # 中国经济站在了十字路口? http://goldread.net/admin/dp/B00EADY1MQ
  #   asin = "B00EADY1MQ"

  #   web_parser = FreeKindleCN::Parser::WebDetail.new asin
  #   assert_equal true, web_parser.parse
  #   assert_equal 200, web_parser.status_code
  #   assert_equal 4200, web_parser.book_price
  #   assert_equal 499, web_parser.kindle_price

  #   mobile_parser = FreeKindleCN::Parser::MobileDetail.new asin
  #   assert_equal true, mobile_parser.parse
  #   assert_equal 200, mobile_parser.status_code
  #   assert_equal 4200, mobile_parser.book_price
  #   assert_equal 499, mobile_parser.kindle_price
  # end

end
