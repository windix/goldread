# encoding: utf-8

require 'asin'
require 'httpclient'

ASIN::Configuration.configure do |config|
  config.secret        = '***REMOVED***'
  config.key           = '***REMOVED***'
  config.associate_tag = '***REMOVED***'
  config.host          = 'webservices.amazon.cn'
end

include ASIN::Client

#item = lookup 'B009ZQB8VA', :ResponseGroup => 'Offers'
item = lookup 'B007OZO03M'
p item


#p item.first.raw.Offers.Offer.OfferListing.Price.FormattedPrice

#p item
