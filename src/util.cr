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

# Exposes a set of utilities to ease the handling of different data types.
# It comes in handy when building protocols further decoding RLP byte-streams.
#
# ```
# decoded = Rlp.decode Bytes[197, 42, 131, 101, 116, 104]
# pp decoded
# # => [Bytes[42], Bytes[101, 116, 104]]
#
# protocol = [] of String | Int32 | BigInt
# protocol << Rlp::Util.bin_to_int decoded[0]
# protocol << Rlp::Util.bin_to_str decoded[1]
# pp protocol
# # => [42, "eth"]
# ```
module Rlp::Util
  # Converts binary `Bytes` to a `BigInt`.
  #
  # Parameters:
  # * `b` (`Bytes`): the binary `Bytes` data to convert.
  #
  # ```
  # Rlp::Util.bin_to_int Bytes[15, 66, 64]
  # # => 1000000
  # ```
  def self.bin_to_int(b : Bytes)
    return BigInt.new b.hexstring, 16
  end

  # Overloads `bin_to_int` with arbitrary data types and raises if
  # input data is not binary.
  #
  # NOTE: Raises in any case if `a` actually contains non-binary or nested data.
  # Shouldn't be used if decoded `Rlp` data could contain nested data structures.
  def self.bin_to_int(a)
    raise "Cannot convert arbitrary data to numbers, please unpack first!"
  end

  # Converts binary `Bytes` to a hex-encoded `String`.
  #
  # Parameters:
  # * `b` (`Bytes`): the binary `Bytes` data to convert.
  #
  # ```
  # Rlp::Util.bin_to_hex Bytes[4, 200, 29]
  # # => "04c81d"
  # ```
  def self.bin_to_hex(b : Bytes)
    h = b.hexstring
    h = "0#{h}" if h.size.odd?
    return h
  end

  # Converts binary `Bytes` to a `String` literal.
  #
  # Parameters:
  # * `b` (`Bytes`): the binary `Bytes` data to convert.
  #
  # ```
  # Rlp::Util.bin_to_str Bytes[97, 98, 99]
  # # => "abc"
  # ```
  def self.bin_to_str(b : Bytes)
    return String.new b
  end

  # Overloads `bin_to_str` with arbitrary data types and raises if
  # input data is not binary.
  #
  # NOTE: Raises in any case if `a` actually contains non-binary or nested data.
  # Shouldn't be used if decoded `Rlp` data could contain nested data structures.
  def self.bin_to_str(a)
    raise "Cannot convert arbitrary data to strings, please unpack first!"
  end

  # Converts integers to binary `Bytes`.
  #
  # Parameters:
  # * `i` (`Int`): the integer to convert.
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

  # Converts integers to hex-encoded `String`s.
  #
  # Parameters:
  # * `i` (`Int`): the integer to convert.
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

  # Converts hex-encoded `String`s to binary `Bytes` data.
  #
  # Parameters:
  # * `h` (`String`): the hex-encoded `String` to convert.
  #
  # ```
  # Rlp::Util.hex_to_bin "04c81d"
  # # => Bytes[4, 200, 29]
  # ```
  def self.hex_to_bin(h : String)
    h = "0#{h}" if h.size.odd?
    return h.hexbytes
  end

  # Converts hex-encoded `String`s to `BigInt`s.
  #
  # Parameters:
  # * `h` (`String`): the hex-encoded `String` to convert.
  #
  # ```
  # Rlp::Util.hex_to_int "04c81d"
  # # => 313373
  # ```
  def self.hex_to_int(h : String)
    h = "0#{h}" if h.size.odd?
    return BigInt.new h, 16
  end

  # Converts hex-encoded `String`s to `String` literals.
  #
  # Parameters:
  # * `h` (`String`): the hex-encoded `String` to convert.
  #
  # ```
  # Rlp::Util.hex_to_str "646f67"
  # # => "dog"
  # ```
  def self.hex_to_str(h : String)
    h = "0#{h}" if h.size.odd?
    return String.new h.hexbytes
  end

  # Converts `String` literals to binary `Bytes` data.
  #
  # Parameters:
  # * `s` (`String`): the `String` literal to convert.
  #
  # ```
  # Rlp::Util.str_to_bin "abc"
  # # => Bytes[97, 98, 99]
  # ```
  def self.str_to_bin(s : String)
    return s.to_slice
  end

  # Converts `String` literals to hex-encoded `String`s.
  #
  # Parameters:
  # * `s` (`String`): the `String` literal to convert.
  #
  # ```
  # Rlp::Util.str_to_hex "dog"
  # # => "646f67"
  # ```
  def self.str_to_hex(s : String)
    return s.to_slice.hexstring
  end

  # Concatenates two `Bytes` slices of `UInt8`.
  #
  # ```
  # a = Bytes[131]
  # b = Bytes[97, 98, 99]
  # Rlp::Util.binary_add a, b
  # # => Bytes[131, 97, 98, 99]
  # ```
  def self.binary_add(a : Bytes, b : Bytes)
    # Concatenate `Bytes` by writing to memory.
    c = IO::Memory.new a.bytesize + b.bytesize

    # Write the `Bytes` from `a`.
    a.each do |v|
      c.write_bytes UInt8.new v
    end

    # Write the `Bytes` from `b`.
    b.each do |v|
      c.write_bytes UInt8.new v
    end

    # Return a slice.
    return c.to_slice
  end
end
