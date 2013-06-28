# encoding: UTF-8

require 'bundler'
Bundler.setup(:default, (ENV['RACK_ENV'] || 'development').to_sym)

require 'asin'
require 'httpclient'
require 'nokogiri'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'list'
require 'item'
require 'asin_config'
require 'db'
