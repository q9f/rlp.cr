# Copyright 2020-23 Afri Schoedon @q9f
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
  # The offset for string literal encoding is `128`.
  OFFSET_STRING = 128

  # The offset for array list encoding is `192`.
  OFFSET_ARRAY = 192

  # The size limit of small data objects to be encoded is `56`.
  LIMIT_SHORT = 56

  # The size limit of large data objects to be encoded is `256 ** 8`.
  LIMIT_LONG = BigInt.new(256) ** BigInt.new(8)

  # An empty string is defined as `0x80`.
  EMPTY_STRING = Bytes[OFFSET_STRING]

  # An empty array is defined as `0xC0`.
  EMPTY_ARRAY = Bytes[OFFSET_ARRAY]
end
