# encoding: UTF-8

require 'bundler'
Bundler.setup(:default, (ENV['RACK_ENV'] || 'development').to_sym)

require 'asin'
require 'httpclient'
require 'nokogiri'

require './list'
require './item'
require './asin_config'
require './db'
