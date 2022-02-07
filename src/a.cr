require "duktape/runtime"

rt = Duktape::Runtime.new(500)

begin
  n = 1
  pp rt.eval(%Q{JSON.stringify({"name":"kings"})})
rescue e : Exception
  pp e.message
end
