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

# Tests for the `Rlp::Util` module.
describe Rlp::Util do
  # Describes all meaningful conversions between numbers, hex strings,
  # string literals, and binary data types.
  it "can convert between types" do
    # Binary bytes to big integers.
    Rlp::Util.bin_to_int(Bytes[5]).should eq 5
    Rlp::Util.bin_to_int(Bytes[15, 66, 64]).should eq 1_000_000

    # Binary bytes to hex strings.
    Rlp::Util.bin_to_hex(Bytes[4, 0]).should eq "0400"
    Rlp::Util.bin_to_hex(Bytes[4, 200, 29]).should eq "04c81d"

    # Binary bytes to string literals
    Rlp::Util.bin_to_str(Bytes[97]).should eq "a"
    Rlp::Util.bin_to_str(Bytes[97, 98, 99]).should eq "abc"

    # Integers to binary bytes.
    Rlp::Util.int_to_bin(5).should eq Bytes[5]
    Rlp::Util.int_to_bin(1_000_000).should eq Bytes[15, 66, 64]

    # Integers to hex strings.
    Rlp::Util.int_to_hex(1024).should eq "0400"
    Rlp::Util.int_to_hex(313373).should eq "04c81d"

    # Hex strings to binary bytes.
    Rlp::Util.hex_to_bin("0400").should eq Bytes[4, 0]
    Rlp::Util.hex_to_bin("04c81d").should eq Bytes[4, 200, 29]

    # Hex strings to big integers.
    Rlp::Util.hex_to_int("0400").should eq 1024
    Rlp::Util.hex_to_int("04c81d").should eq 313373

    # Hex strings to string literals.
    Rlp::Util.hex_to_str("64").should eq "d"
    Rlp::Util.hex_to_str("646f67").should eq "dog"

    # String literals to binary bytes.
    Rlp::Util.str_to_bin("a").should eq Bytes[97]
    Rlp::Util.str_to_bin("abc").should eq Bytes[97, 98, 99]

    # String literals to hex strings.
    Rlp::Util.str_to_hex("d").should eq "64"
    Rlp::Util.str_to_hex("dog").should eq "646f67"
  end

  it "can concatenate bytes" do
    # Addition with empty slice should always equal the input byte.
    a = Slice(UInt8).empty
    b = Bytes[0]
    Rlp::Util.binary_add(a, a).should eq a
    Rlp::Util.binary_add(a, b).should eq b
    Rlp::Util.binary_add(b, a).should eq b

    # Prefixing or suffixing with a single byte.
    c = Bytes[97]
    d = Bytes[98, 99]
    Rlp::Util.binary_add(c, d).should eq Bytes[97, 98, 99]
    Rlp::Util.binary_add(d, c).should eq Bytes[98, 99, 97]

    # Concatenation of more complex bytes.
    e = Rlp.encode(1_000_000)
    f = Rlp.encode("A cat with a short string.")
    Rlp::Util.binary_add(e, f).should eq Bytes[131, 15, 66, 64, 154, 65, 32, 99, 97, 116, 32, 119, 105, 116, 104, 32, 97, 32, 115, 104, 111, 114, 116, 32, 115, 116, 114, 105, 110, 103, 46]
    Rlp::Util.binary_add(f, e).should eq Bytes[154, 65, 32, 99, 97, 116, 32, 119, 105, 116, 104, 32, 97, 32, 115, 104, 111, 114, 116, 32, 115, 116, 114, 105, 110, 103, 46, 131, 15, 66, 64]
  end
end
