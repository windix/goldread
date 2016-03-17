require __dir__ + "/../bootstrap"
require 'webmock'
require 'pry'

include WebMock::API

file_path = ARGV[0] || abort("file is missing")

stub_request(:any, %r[www.amazon.cn/.*]).to_return(
  :body => File.open(file_path)
)

parser = FreeKindleCN::Parser.factory('mobile', 'ASIN')

puts parser.inspect.to_yaml
