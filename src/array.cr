# Copyright 2020 @q9f
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The `Rlp` module implementing Ethereum's Recursive Length Prefix
# for arbitrary data encoding and decoding.
module Rlp
  # An recursive array alias for arrays of unknown nesting depth.
  #
  # ```crystal
  # a = [] of RecursiveArray
  # a << ""
  # a << Bytes[128]
  # a << [] of RecursiveArray
  # ```
  #
  # TODO: The recursive alias might be deprecated in future, 
  # ref: [crystal-lang/crystal#5155](https://github.com/crystal-lang/crystal/issues/5155). 
  # it's worth considering a custom struct holding a `@data` property
  # of type `String | Bytes | Array(RecursiveArray)` and forward missing methods,
  # ref: [crystal-lang/crystal#8719](https://github.com/crystal-lang/crystal/issues/8719).
  alias RecursiveArray = String | Bytes | Array(RecursiveArray)
end
