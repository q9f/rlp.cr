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

require "./util.cr"

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

  # rlp-encodes binary data
  def self.encode(b : Bytes)
    # if the byte-array contains a single byte solely
    # and that single byte is less than 128 (OFFSET_STRING)
    # then the input is exactly equal to the output
    if b.bytesize === 1 && b.first < OFFSET_STRING
      return b
    end

    # if the byte-array contains fewer than 56 bytes (LIMIT_SHORT)
    # then the output is equal to the input prefixed by the byte
    # equal to the length of the byte array plus 128 (OFFSET_STRING)
    if b.bytesize < LIMIT_SHORT
      # length of the byte array plus 128 (OFFSET_STRING)
      prefix = UInt8.new b.bytesize + OFFSET_STRING

      # concatenate bytes by writing to memory
      result = IO::Memory.new b.bytesize + 1

      # write the prefix byte
      result.write_bytes prefix

      # write each data byte
      b.each do |v|
        result.write_bytes UInt8.new v
      end
      return result.to_slice
    end

    # otherwise, the output is equal to the input prefixed by the
    # minimal-length byte-array which when interpreted as a big-endian integer
    # is equal to the length of the input byte array, which is itself prefixed
    # by the number of bytes required to faithfully encode this length value plus 183.
    if b.bytesize < LIMIT_LONG
      # get the size of the data
      data_size = b.bytesize

      # get the size required to store the size as byte slice
      header_size = bytes_size BigInt.new data_size

      # get the binary representation of the data size
      header = Util.int_to_bin BigInt.new data_size

      # faithfully encode this length value plus 183.
      prefix = UInt8.new header.bytesize + OFFSET_STRING + LIMIT_SHORT - 1

      # create a memory buffer for the prefix, header, and data
      result = IO::Memory.new 1 + header_size + data_size

      # write the prefix byte
      result.write_bytes prefix

      # write the data size header
      header.each do |l|
        result.write_bytes l
      end

      # write each data byte
      b.each do |v|
        result.write_bytes UInt8.new v
      end
      return result.to_slice
    else
      raise "invalid data provided (size out of range: #{b.bytesize})"
    end
  end

  # rlp-encodes lists data
  def self.encode(l : Array)
    # return an empty array byte if we detect an empty list
    if l.empty?
      return EMPTY_ARRAY
    end

    # If the concatenated serializations of each contained item are less than 56 bytes in length, then the output is equal to that concatenation prefixed by the byte equal to the length of this byte array plus 192.
    if l.size < LIMIT_SHORT
      l.each do |a|
        pp a # @TODO
      end
    end

    # Otherwise, the output is equal to the concatenated serializations prefixed by the minimal-length byte-array which when interpreted as a big-endian integer is equal to the length of the concatenated serializations byte array, which is itself prefixed by the number of bytes required to faithfully encode this length value plus 247.
    if l.size < LIMIT_LONG
      l.each do |a|
        pp a # @TODO
      end
    else
      raise "invalid list provided (size out of range: #{l.size})"
    end
  end

  # rlp-encodes string data
  def self.encode(s : String)
    if s.empty?
      # return an empty string byte if we detect an empty string
      return EMPTY_STRING
    elsif s.size < LIMIT_LONG
      # a string is simply handled as binary data here
      return encode Util.str_to_bin s
    else
      raise "invalid string provided (size out of range: #{s.size})"
    end
  end

  # rlp-encodes scalar data
  def self.encode(i : BigInt)
    if i === 0
      # the scalar 0 is treated as empty string literal, not as zero byte.
      return EMPTY_STRING
    elsif i > 0 && i < LIMIT_LONG
      # if rlp is used to encode a scalar, defined only as a positive integer
      # it must be specified as the shortest byte array such that the
      # big-endian interpretation of it is equal.
      return encode Util.int_to_bin i
    else
      raise "invalid scalar provided (out of range: #{i})"
    end
  end

  # decodes arbitrary data from a recursive length prefix blob
  def self.decode(blob)
  end

  # gets the length of the input data using the first byte
  def self.get_length(data : Bytes)
    length = -9
    prefix = data.first
    if prefix < OFFSET_STRING
      length = 1
    elsif prefix < OFFSET_ARRAY
      length = 1 + prefix - OFFSET_STRING
    else
      length = 1 + prefix - OFFSET_ARRAY
    end
    return length
  end

  # gets the number of bytes required to represent a big integer
  def self.bytes_size(i : BigInt)
    b = Util.int_to_bin i
    return b.size
  end
end
