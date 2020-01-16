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

require "./spec_helper"

# Tests for the `Rlp` module.
describe Rlp do
  # This just ensures the constants are never tampered with.
  it "can define valid constants" do
    # The offset for string literal encoding is `128`.
    Rlp::OFFSET_STRING.should eq 128

    # The offset for array list encoding is `192`.
    Rlp::OFFSET_ARRAY.should eq 192

    # The size limit of small data objects to be encoded is `56`.
    Rlp::LIMIT_SHORT.should eq 56

    # The size limit of large data objects to be encoded is `256 ** 8`.
    Rlp::LIMIT_LONG.should eq BigInt.new "18446744073709551616"

    # An empty string is defined as `0x80`.
    Rlp::EMPTY_STRING.should eq Bytes[128]

    # An empty array is defined as `0xC0`.
    Rlp::EMPTY_ARRAY.should eq Bytes[192]
  end

  it "can find the correct size of a byte representation" do
    Rlp.bytes_size(BigInt.new).should eq 1
    Rlp.bytes_size(BigInt.new(255)).should eq 1
    Rlp.bytes_size(BigInt.new(256)).should eq 2
    Rlp.bytes_size(BigInt.new("18446744073709551616")).should eq 9
    Rlp.bytes_size(BigInt.new("18446744073709551616")).should eq Rlp::Util.int_to_hex(BigInt.new("18446744073709551616")).size // 2
  end
end
