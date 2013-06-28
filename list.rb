# encoding: UTF-8

module FreeKindleCN
  class AsinList
    def initialize
      @client = HTTPClient.new :agent_name => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.37 Safari/537.36'
    end

    # 销售飙升榜
    def movers_and_shakers(total_pages = 1)
      handle_page("movers-and-shakers", total_pages)
    end

    # 新品排行榜
    def new_releases(total_pages = 1)
      handle_page("new-releases", total_pages)
    end

    # 商品销售榜 (付费, 免费)
    def bestsellers(total_pages = 1)
      all = handle_page("bestsellers", total_pages)
      [all.odd_values, all.even_values]
    end

    def daily_deal
      url = "http://www.amazon.cn/gp/feature.html/ref=amb_link_30648212_2?ie=UTF8&docId=126758&pf_rd_m=A1AJ19PSB66TGU&pf_rd_s=right-top&pf_rd_t=101&pf_rd_p=70106812&pf_rd_i=116169071"
      content = @client.get(url).content

      doc = Nokogiri::HTML(content, nil, 'UTF-8')

      # TODO weekly deals

      # doc.at_css('span.price').content
      doc.at_css('img[alt="立即购买"]').parent['href'][%r{/gp/product/([A-Z0-9]+)/}, 1]
    end

    private

    def handle_page(name, total_pages)
      all = []

      (1..total_pages).each do |i|
        all += fetch_page(name, i)
      end

      all
    end

    def fetch_page(name, page)
      fetch(name, page, true) + fetch(name, page, false)
    end

    def fetch(name, page, above_the_fold)
      node = (name == "bestsellers") ? "116169071" : ""
      above_the_fold_param = above_the_fold ? "" : "&isAboveTheFold=0"

      url = "http://www.amazon.cn/gp/#{name}/digital-text/#{node}?ie=UTF8&pg=#{page}&ajax=1#{above_the_fold_param}"
      content = @client.get(url).content

      doc = Nokogiri::HTML(content, nil, 'UTF-8')

      doc.css("span.asinReviewsSummary").collect { |span| span['name'] }
      #doc.css("div.zg_title a").collect { |a| a.content }
    end

  end

end
