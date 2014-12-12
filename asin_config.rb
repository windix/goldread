require 'asin'
require 'asin/adapter'
require 'rash'
require 'item'
require 'asin_helper'
require 'updater'

ASIN::Configuration.configure do |config|
  config.secret        = '***REMOVED***'
  config.key           = '***REMOVED***'
  config.associate_tag = '***REMOVED***'
  config.host          = 'webservices.amazon.cn'
  config.logger        = nil
end
