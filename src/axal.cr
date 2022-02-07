require "duktape/runtime"
require "crest"
require "./lang/**"

alias X = Nil | Bool | Float64 | String | Array(X) | Array(Duktape::JSPrimitive) | Hash(String, X) | Hash(String, Duktape::JSPrimitive)
