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

  # A recursive array alias for arrays of unknown nesting depth.
  alias RecursiveArray = String | Bytes | Array(RecursiveArray)

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
      p = Bytes[prefix]

      # prefix the data with the prefix byte
      return Util.binary_add p, b
    end

    # otherwise, the output is equal to the input prefixed by the
    # minimal-length byte-array which when interpreted as a big-endian integer
    # is equal to the length of the input byte array, which is itself prefixed
    # by the number of bytes required to faithfully encode this length value plus 183.
    if b.bytesize < LIMIT_LONG
      # get the size of the data
      data_size = b.bytesize

      # get the binary representation of the data size
      header = Util.int_to_bin data_size

      # faithfully encode this length value plus 183.
      prefix = UInt8.new header.bytesize + OFFSET_STRING + LIMIT_SHORT - 1
      p = Bytes[prefix]

      # prefix the header with the prefix byte
      header = Util.binary_add p, header

      # prefix the data with the header data
      return Util.binary_add header, b
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

    # concatenate the serializations of each contained item
    body = Slice(UInt8).empty
    l.each do |a|
      if body.size === 0
        body = encode a
      else
        body = Util.binary_add body, encode a
      end
    end

    # if the concatenated serializations of each contained item are
    # less than 56 bytes in length, then the output is equal to
    # that concatenation prefixed by the byte equal to the length of
    # this byte array plus 192 (OFFSET_ARRAY)
    if body.bytesize < LIMIT_SHORT
      # length of this byte array plus 192 (OFFSET_ARRAY)
      prefix = UInt8.new body.bytesize + OFFSET_ARRAY
      p = Bytes[prefix]

      # prefix the data with the prefix byte
      return Util.binary_add p, body
    end

    # otherwise, the output is equal to the concatenated serializations
    # prefixed by the minimal-length byte-array which when interpreted as
    # a big-endian integer is equal to the length of the concatenated
    # serializations byte array, which is itself prefixed by the number of bytes
    # required to faithfully encode this length value plus 247.
    if body.bytesize < LIMIT_LONG
      # get the size of the data
      data_size = body.bytesize

      # get the binary representation of the data size
      header = Util.int_to_bin data_size

      # faithfully encode this length value plus 247.
      prefix = UInt8.new header.bytesize + OFFSET_ARRAY + LIMIT_SHORT - 1
      p = Bytes[prefix]

      # prefix the header with the prefix byte
      header = Util.binary_add p, header

      # prefix the data with the header data
      return Util.binary_add header, body
    else
      raise "invalid list provided (size out of range: #{body.bytesize})"
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
  def self.encode(i : Int)
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

  # rlp-encodes characters
  def self.encode(c : Char)
    # we simpy treat characters as strings
    return encode c.to_s
  end

  # rlp-encodes boolean data
  def self.encode(o : Bool)
    if o
      # basically true is 1
      return Bytes[1]
    else
      # and false is 0 which is equal the empty string
      return EMPTY_STRING
    end
  end

  # decodes arbitrary data from a recursive length prefix blob.
  # note, that the returned data only restores the data structure.
  # it's up to the protocol to determine the meaning of the data
  # as defined in ethereum's design rationale.
  def self.decode(rlp : Bytes)
    
    # catch known edgecases and return early
    if rlp === EMPTY_STRING
    
      # we return an string here instead of binary because we know for
      # certain that this value represents an empty string
      return ""
    elsif rlp === EMPTY_ARRAY
    
      # we return an array here instead of binary because we know for
      # certain that this value represents an empty array
      return [] of RecursiveArray
    end

    # firstly, takes a look at the prefix byte
    prefix = rlp.first
    length = rlp.bytesize
    if prefix < OFFSET_STRING && length === 1

      # if the value is lower 128, return the byte directly
      return rlp
    elsif prefix < OFFSET_STRING + LIMIT_SHORT

      # if it's a short string, cut off the prefix and return the string
      offset = 1
      return rlp[offset, length - offset]
    elsif prefix < OFFSET_ARRAY

      # if it's a long string, cut off the prefix header and return the string
      offset = 1 + prefix - 183
      return rlp[offset, length - offset]
    else

      # if it's not a byte or a string, then we have any type of array here
      result = [] of RecursiveArray
      if prefix < OFFSET_ARRAY + LIMIT_SHORT

        # if it's a small array, cut off the prefix
        offset = 1
        rlp = rlp[offset, length - offset]
      else

        # if it's a massive array, cut off the prefix header
        offset = 1 + prefix - 247
        rlp = rlp[offset, length - offset]
      end
      
      # now we recursively decode each item nested in the array
      while rlp.bytesize > 0
        
        # getting the prefix of each item (if any)
        prefix = rlp.first
        length = 0
        offset = 0
        if prefix < OFFSET_STRING

          # this is a nested byte of length 1
          length = 1
        elsif prefix < OFFSET_STRING + LIMIT_SHORT

          # this is a nested short string literal
          length = 1 + prefix - OFFSET_STRING
        elsif prefix < OFFSET_ARRAY

          # this is a nested long string literal
          header_size = prefix - 183
          header = rlp[2, 2 + header_size]
          length = 1 + header_size + Util.bin_to_int header
        elsif prefix < OFFSET_ARRAY + LIMIT_SHORT

          # this is a nested small array
          length = 1 + prefix - OFFSET_ARRAY
        else

          # this is a nested massive array
          header_size = prefix - 247
          header = rlp[2, 2 + header_size]
          length = 1 + header_size + Util.bin_to_int header
        end

        # we push the decoded item to the result
        result << decode rlp[offset, length]
        offset = length
        length = rlp.size - length

        # and move on with the rest of the data
        rlp = rlp[offset, length]
      end

      # until we decoded all items and return the resulting structure
      return result
    end
  end

  # decodes rlp data from hex-encoded strings
  def self.decode(hex : String)
    return decode Util.hex_to_bin hex
  end
end
