# encoding: UTF-8

require 'bundler'
Bundler.setup(:default, (ENV['RACK_ENV'] || 'development').to_sym)

require 'asin'
require 'httpclient'
require 'nokogiri'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'monkey_patch'
require 'list'
require 'item'
require 'asin_config'
require 'db'

# Constants
module FreeKindleCN
  DATE_FORMAT = '%Y-%m-%d'
  DATETIME_FORMAT = '%Y-%m-%d %H:%M'
end
