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

# All numbers will be handled as big integers
require "big/big_int"

# Exposes a set of utilities to ease the handling of different data types.
module Rlp::Util
  # Converts binary bytes to a big integer.
  #
  # Parameters:
  # * `b` (`Bytes`): the binary bytes data to convert.
  #
  # ```
  # Rlp::Util.bin_to_int Bytes[15, 66, 64])
  # # => 1000000
  # ```
  def self.bin_to_int(b : Bytes)
    return BigInt.new b.hexstring, 16
  end

  # Converts binary bytes to a hex-encoded string.
  #
  # Parameters:
  # * `b` (`Bytes`): the binary bytes data to convert.
  #
  # ```
  # Rlp::Util.bin_to_hex Bytes[4, 200, 29])
  # # => "04c81d"
  # ```
  def self.bin_to_hex(b : Bytes)
    h = b.hexstring
    h = "0#{h}" if h.size.odd?
    return h
  end

  # Converts binary bytes to a string literal.
  #
  # Parameters:
  # * `b` (`Bytes`): the binary bytes data to convert.
  #
  # ```
  # Rlp::Util.bin_to_str Bytes[97, 98, 99])
  # # => "abc"
  # ```
  def self.bin_to_str(b : Bytes)
    return String.new b
  end

  # Converts big integers to binary bytes.
  #
  # Parameters:
  # * `i` (`Int`): the big integer to convert.
  #
  # ```
  # Rlp::Util.int_to_bin 1_000_000
  # # => Bytes[15, 66, 64]
  # ```
  def self.int_to_bin(i : Int)
    h = i.to_s 16
    h = "0#{h}" if h.size.odd?
    return h.hexbytes
  end

  # Converts big integers to hex-encoded strings.
  #
  # Parameters:
  # * `i` (`Int`): the big integer to convert.
  #
  # ```
  # Rlp::Util.int_to_hex 313_373
  # # => "04c81d"
  # ```
  def self.int_to_hex(i : Int)
    h = i.to_s 16
    h = "0#{h}" if h.size.odd?
    return h
  end

  # Converts hex-encoded strings to binary bytes data.
  #
  # Parameters:
  # * `h` (`String`): the hex-encoded string to convert.
  #
  # ```
  # Rlp::Util.hex_to_bin "04c81d"
  # # => Bytes[4, 200, 29]
  # ```
  def self.hex_to_bin(h : String)
    h = "0#{h}" if h.size.odd?
    return h.hexbytes
  end

  # Converts hex-encoded strings to big integers.
  #
  # Parameters:
  # * `h` (`String`): the hex-encoded string to convert.
  #
  # ```
  # Rlp::Util.hex_to_int "04c81d"
  # # => 313373
  # ```
  def self.hex_to_int(h : String)
    h = "0#{h}" if h.size.odd?
    return BigInt.new h, 16
  end

  # Converts hex-encoded strings to string literals.
  #
  # Parameters:
  # * `h` (`String`): the hex-encoded string to convert.
  #
  # ```
  # Rlp::Util.hex_to_str "646f67"
  # # => "dog"
  # ```
  def self.hex_to_str(h : String)
    h = "0#{h}" if h.size.odd?
    return String.new h.hexbytes
  end

  # Converts string literals to binary bytes data.
  #
  # Parameters:
  # * `s` (`String`): the string literal to convert.
  #
  # ```
  # Rlp::Util.str_to_bin "abc"
  # # => Bytes[97, 98, 99]
  # ```
  def self.str_to_bin(s : String)
    return s.to_slice
  end

  # Converts string literals to hex-encoded strings.
  #
  # Parameters:
  # * `s` (`String`): the string literal to convert.
  #
  # ```
  # Rlp::Util.str_to_hex "dog"
  # # => "646f67"
  # ```
  def self.str_to_hex(s : String)
    return s.to_slice.hexstring
  end

  # concatenates two byte slices of uint8
  def self.binary_add(a : Bytes, b : Bytes)
    # concatenate bytes by writing to memory
    c = IO::Memory.new a.bytesize + b.bytesize

    # write the bytes from `a`
    a.each do |v|
      c.write_bytes UInt8.new v
    end

    # write the bytes from `b`
    b.each do |v|
      c.write_bytes UInt8.new v
    end

    # return a slice
    return c.to_slice
  end
end
