require "baked_file_system"
require "duktape/runtime"
require "crest"

require "./lang/**"

# alias X = Nil | Bool | Float64 | String | Array(X) | Array(Duktape::JSPrimitive) | Hash(String, X) | Hash(String, Duktape::JSPrimitive)
alias X = Nil | Bool | Float64 | String | Array(X) | Hash(String, X)


class FileStorage
  extend BakedFileSystem
  bake_folder "core"
end