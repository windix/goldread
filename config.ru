require './freekindlecn'
require './web/home'
require './web/admin'

run Rack::URLMap.new({
  '/' => FreeKindleCN::Web::Home.new,
  '/admin' => FreeKindleCN::Web::Admin.new
})
