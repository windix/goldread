# DataMapper::Logger.new($stdout, :debug)

if FreeKindleCN::CONTEXT == :production
  DataMapper.setup(:default, "mysql://root:***REMOVED***@localhost/goldread")
else
  #DataMapper.setup(:default, "sqlite://#{File.expand_path(File.dirname(__FILE__))}/test.db")
  DataMapper.setup(:default, "mysql://root:***REMOVED***@localhost/goldread")
end

DataMapper::Model.raise_on_save_failure = true
