# encoding: UTF-8

require 'bundler'

# Constants
module FreeKindleCN
  CONTEXT = ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development

  DATE_FORMAT = '%Y-%m-%d'
  DATETIME_FORMAT = '%Y-%m-%d %H:%M'
  MYSQL_FORMAT = '%Y-%m-%d %H:%M:%S'

  ADMIN_ITEMS_PER_PAGE = 50
end

Bundler.setup(:default, FreeKindleCN::CONTEXT)

require 'log_buddy'

LogBuddy.init
LogBuddy.logger.level = (FreeKindleCN::CONTEXT == :development) ? Logger::DEBUG : Logger::INFO

logger.info "Current Environment: #{FreeKindleCN::CONTEXT}"

require 'asin'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'monkey_patch'
require 'parser'
require 'list'
require 'item'
require 'asin_config'
require 'db'
require 'db_views'
require 'tweet'
require 'douban_config'
