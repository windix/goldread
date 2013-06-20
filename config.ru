require './freekindlecn'
require './web/admin'

run Rack::URLMap.new({
  '/admin' => FreeKindleCN::Web::Admin.new

})
