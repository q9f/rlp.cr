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

require "big/big_int"

require "./array.cr"
require "./constants.cr"
require "./util.cr"

# The `Rlp` module implementing Ethereum's Recursive Length Prefix
# for arbitrary data encoding and decoding.
module Rlp
  # RLP-encodes binary `Bytes` data.
  #
  # Parameters:
  # * `b` (`Bytes`): the binary `Bytes` data to encode.
  #
  # ```
  # Rlp.encode Bytes[15, 66, 64]
  # # => Bytes[131, 15, 66, 64]
  # ```
  def self.encode(b : Bytes)
    # If the byte-array contains a single byte solely
    # and that single byte is less than `128` (`OFFSET_STRING`)
    # then the input is exactly equal to the output.
    if b.bytesize === 1 && b.first < OFFSET_STRING
      return b
    end

    # If the byte-array contains fewer than `56` bytes (`LIMIT_SHORT`)
    # then the output is equal to the input prefixed by the byte
    # equal to the length of the byte array plus `128` (`OFFSET_STRING`).
    if b.bytesize < LIMIT_SHORT
      # The length of the byte array plus `128` (`OFFSET_STRING`).
      prefix = UInt8.new b.bytesize + OFFSET_STRING
      p = Bytes[prefix]

      # Prefixes the data with the prefix byte.
      return Util.binary_add p, b
    end

    # Otherwise, the output is equal to the input prefixed by the
    # minimal-length byte-array which when interpreted as a big-endian integer
    # is equal to the length of the input byte array, which is itself prefixed
    # by the number of bytes required to faithfully encode this length value plus `183`.
    if b.bytesize < LIMIT_LONG
      # Gets the size of the data.
      data_size = b.bytesize

      # Gets the binary representation of the data size.
      header = Util.int_to_bin data_size

      # Faithfully encodes this length value plus `183`.
      prefix = UInt8.new header.bytesize + OFFSET_STRING + LIMIT_SHORT - 1
      p = Bytes[prefix]

      # Prefixes the header with the prefix byte.
      header = Util.binary_add p, header

      # Prefixes the data with the header data.
      Util.binary_add header, b
    else
      raise "Invalid data provided (size out of range: #{b.bytesize})"
    end
  end

  # RLP-encodes nested `Array` data.
  #
  # Parameters:
  # * `l` (`Array`): the nested `Array` data to encode.
  #
  # ```
  # Rlp.encode [[""], [""]]
  # # => Bytes[196, 193, 128, 193, 128]
  # ```
  def self.encode(l : Array)
    # Returns an empty array byte if we detect an empty list.
    if l.empty?
      return EMPTY_ARRAY
    end

    # Concatenates the serializations of each contained item.
    body = Slice(UInt8).empty
    l.each do |a|
      if body.size === 0
        body = encode a
      else
        body = Util.binary_add body, encode a
      end
    end

    # If the concatenated serializations of each contained item are
    # less than `56` bytes in length, then the output is equal to
    # that concatenation prefixed by the byte equal to the length of
    # this byte array plus `192` (`OFFSET_ARRAY`).
    if body.bytesize < LIMIT_SHORT
      # The length of this byte array plus `192` (`OFFSET_ARRAY`).
      prefix = UInt8.new body.bytesize + OFFSET_ARRAY
      p = Bytes[prefix]

      # Prefixes the data with the prefix byte.
      return Util.binary_add p, body
    end

    # Otherwise, the output is equal to the concatenated serializations
    # prefixed by the minimal-length byte-array which when interpreted as
    # a big-endian integer is equal to the length of the concatenated
    # serializations byte array, which is itself prefixed by the number of bytes
    # required to faithfully encode this length value plus `247`.
    if body.bytesize < LIMIT_LONG
      # Gets the size of the data.
      data_size = body.bytesize

      # Gets the binary representation of the data size.
      header = Util.int_to_bin data_size

      # Faithfully encodes this length value plus `247`.
      prefix = UInt8.new header.bytesize + OFFSET_ARRAY + LIMIT_SHORT - 1
      p = Bytes[prefix]

      # Prefixes the header with the prefix byte.
      header = Util.binary_add p, header

      # Prefixes the data with the header data.
      Util.binary_add header, body
    else
      raise "Invalid list provided (size out of range: #{body.bytesize})"
    end
  end

  # RLP-encodes `String` literals.
  #
  # Parameters:
  # * `s` (`String`): the `String` literal to encode.
  #
  # ```
  # Rlp.encode "dog"
  # # => Bytes[131, 100, 111, 103]
  # ```
  def self.encode(s : String)
    if s.empty?
      # Returns an empty string byte if we detect an empty string
      EMPTY_STRING
    elsif s.size < LIMIT_LONG
      # A string is simply handled as binary data here.
      encode Util.str_to_bin s
    else
      raise "Invalid string provided (size out of range: #{s.size})"
    end
  end

  # RLP-encodes scalar `Int` numbers.
  #
  # Parameters:
  # * `i` (`Int`): the scalar `Int` number to encode.
  #
  # ```
  # Rlp.encode 1_000_000
  # # => Bytes[131, 15, 66, 64]
  # ```
  def self.encode(i : Int)
    if i === 0
      # The scalar `0` is treated as empty string literal, not as zero byte.
      EMPTY_STRING
    elsif i > 0 && i < LIMIT_LONG
      # If `Rlp` is used to encode a scalar, defined only as a positive integer
      # it must be specified as the shortest byte array such that the
      # big-endian interpretation of it is equal.
      encode Util.int_to_bin i
    else
      raise "Invalid scalar provided (out of range: #{i})"
    end
  end

  # RLP-encodes `Char` characters.
  #
  # Parameters:
  # * `c` (`Char`): the `Char` character to encode.
  #
  # ```
  # Rlp.encode 'x'
  # # => Bytes[120]
  # ```
  def self.encode(c : Char)
    # We simpy treat characters as strings.
    encode c.to_s
  end

  # RLP-encodes boolean `Bool` values.
  #
  # Parameters:
  # * `o` (`Bool`): the boolean `Bool` value to encode.
  #
  # ```
  # Rlp.encode true
  # # => Bytes[1]
  # ```
  def self.encode(o : Bool)
    if o
      # Basically, `true` is `1`.
      Bytes[1]
    else
      # And `false` is `0` which is equal the empty string `""`.
      EMPTY_STRING
    end
  end

  # Decodes arbitrary data structures from a given binary
  # recursive length prefix data stream.
  #
  # Parameters:
  # * `rlp` (`Bytes`): the encoded `Rlp` data to decode.
  #
  # ```
  # Rlp.decode Bytes[195, 193, 192, 192]
  # # => [[[]], []]
  # ```
  #
  # NOTE: The returned data only restores the data structure.
  # It's up to the protocol to determine the meaning of the data
  # as defined in Ethereum's design rationale.
  def self.decode(rlp : Bytes)
    # Catches known edgecases and returns early.
    if rlp === EMPTY_STRING
      # We return a string here instead of binary because we know for
      # certain that this value represents an empty string.
      return ""
    elsif rlp === EMPTY_ARRAY
      # We return an array here instead of binary because we know for
      # certain that this value represents an empty array.
      return [] of RecursiveArray
    end

    # Firstly, takes a look at the prefix byte.
    prefix = rlp.first
    length = rlp.bytesize
    if prefix < OFFSET_STRING && length === 1
      # If the value is lower than `128`, return the byte directly.
      rlp
    elsif prefix < OFFSET_STRING + LIMIT_SHORT
      # If it's a short string, cut off the prefix and return the string.
      offset = 1
      rlp[offset, length - offset]
    elsif prefix < OFFSET_ARRAY
      # If it's a long string, cut off the prefix header and return the string.
      offset = 1 + prefix - 183
      rlp[offset, length - offset]
    else
      # If it's not a byte or a string, then we have some type of array here.
      result = [] of RecursiveArray
      if prefix < OFFSET_ARRAY + LIMIT_SHORT
        # If it's a small array, cut off the prefix.
        offset = 1
        rlp = rlp[offset, length - offset]
      else
        # If it's a massive array, cut off the prefix and header.
        offset = 1 + prefix - 247
        rlp = rlp[offset, length - offset]
      end

      # Now we recursively decode each item nested in the array.
      while rlp.bytesize > 0
        # Getting the prefix of each nested item (if any).
        prefix = rlp.first
        length = 0
        if prefix < OFFSET_STRING
          # This is a nested byte of length `1`.
          length = 1
        elsif prefix < OFFSET_STRING + LIMIT_SHORT
          # This is a nested short string literal.
          length = 1 + prefix - OFFSET_STRING
        elsif prefix < OFFSET_ARRAY
          # This is a nested long string literal.
          header_size = prefix - 183
          header = rlp[1, header_size]
          length = 1 + header_size + Util.bin_to_int header
        elsif prefix < OFFSET_ARRAY + LIMIT_SHORT
          # This is a nested small array.
          length = 1 + prefix - OFFSET_ARRAY
        else
          # This is a nested massive array.
          header_size = prefix - 247
          header = rlp[1, header_size]
          length = 1 + header_size + Util.bin_to_int header
        end

        # We push the recursively decoded item to the result.
        result << decode rlp[0, length]
        offset = length
        length = rlp.size - length

        # And move on with the rest of the data.
        rlp = rlp[offset, length]
      end

      # Until we decoded all items and return the resulting structure.
      result
    end
  end

  # Decodes arbitrary data structures from a given hex-encoded
  # recursive length prefix data stream.
  #
  # Parameters:
  # * `hex` (`String`): the encoded `Rlp` data to decode.
  #
  # ```
  # Rlp.decode "c7c0c1c0c3c0c1c0"
  # # => [[], [[]], [[], [[]]]]
  # ```
  #
  # NOTE: The returned data only restores the data structure.
  # It's up to the protocol to determine the meaning of the data
  # as defined in Ethereum's design rationale.
  def self.decode(hex : String)
    decode Util.hex_to_bin hex
  end
end
