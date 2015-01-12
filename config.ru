lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'freekindlecn'
require './web/home'
require './web/admin'
require 'sidekiq/web'

run Rack::URLMap.new({
  '/' => FreeKindleCN::Web::Home.new,
  '/admin' => FreeKindleCN::Web::Admin.new,
  '/sidekiq' => Sidekiq::Web.new
})
