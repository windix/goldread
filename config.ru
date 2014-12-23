require './freekindlecn'
require './web/home'
require './web/admin'
require 'sidekiq/web'

run Rack::URLMap.new({
  '/' => FreeKindleCN::Web::Home.new,
  '/admin' => FreeKindleCN::Web::Admin.new,
  '/sidekiq' => Sidekiq::Web.new
})
