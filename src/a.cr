# require "duktape/runtime"



# # r = rt.eval <<-JS
# #  var s = {"name":"kings"};
# #  JSON.stringify(s);
# # JS

# def go
# name = "kings"
# rt = Duktape::Runtime.new(500)
# r = rt.eval %Q{ var s = {"name":"#{name}"}; s; }
# pp r
# rescue e : Exception 
#     pp e.message
# end

# go


# def a
#     1
# end

# pp -a()


pp false && nil