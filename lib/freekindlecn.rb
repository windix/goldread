# encoding: UTF-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'bundler'
require 'freekindlecn/version'

# Constants
module FreeKindleCN
  CONTEXT = ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development

  DATE_FORMAT = '%Y-%m-%d'
  DATETIME_FORMAT = '%Y-%m-%d %H:%M'
  MYSQL_FORMAT = '%Y-%m-%d %H:%M:%S'

  ADMIN_ITEMS_PER_PAGE = 50

  BASE_PATH = File.expand_path('../../', __FILE__) 
  CONFIG_PATH = BASE_PATH + "/config"
  WEB_PUBLIC_PATH = BASE_PATH + "/web"
  BOOK_IMAGE_CACHE_PATH = WEB_PUBLIC_PATH + "/images/asin"
end

Bundler.setup(:default, FreeKindleCN::CONTEXT)

#require 'newrelic_rpm' if FreeKindleCN::CONTEXT == :production

require 'log_buddy'

LogBuddy.init
LogBuddy.logger.level = (FreeKindleCN::CONTEXT == :development) ? Logger::DEBUG : Logger::INFO

logger.info "Current Environment: #{FreeKindleCN::CONTEXT}"

require 'monkey_patch'

require 'freekindlecn/parser'

require 'asin'
require 'asin/adapter'
require 'rash'
require 'asin_helper'
require FreeKindleCN::CONFIG_PATH + "/asin"

require 'freekindlecn/item'
require 'freekindlecn/updater'
require 'freekindlecn/asin_list'

require 'freekindlecn/db'
require 'freekindlecn/db/item_view'
require 'freekindlecn/tweet'

require 'douban_helper'

require 'freekindlecn/worker/fetch_worker'

