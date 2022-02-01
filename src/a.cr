# require "duktape/runtime"

# rt = Duktape::Runtime.new(500)

# begin
#     n = 1
# pp rt.eval("1 + #{n}")
# rescue e : Exception
#     pp e.message
# end

a = "hello `name` and `age`"
# if md = a.match(/`(.+)?`/)
#     pp md
# end

vars = a.scan(/`(.+?)`/)
vars.each do |v|
  a = a.gsub(v[1], "???")
end

pp a
