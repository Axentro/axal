require "duktape/runtime"
require "./lang/**"

alias X = Nil | Bool | Float64 | String | Array(X) | Array(Duktape::JSPrimitive) | Hash(String, X)
