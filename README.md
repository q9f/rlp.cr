# rlp.cr

[![Build Status](https://img.shields.io/github/workflow/status/q9f/rlp.cr/Nightly)](https://github.com/q9f/rlp.cr/actions)
[![Documentation](https://img.shields.io/badge/docs-html-black)](https://q9f.github.io/rlp.cr/)
[![Release](https://img.shields.io/github/v/release/q9f/rlp.cr?include_prereleases&color=black)](https://github.com/q9f/rlp.cr/releases/latest)
[![Language](https://img.shields.io/github/languages/top/q9f/rlp.cr?color=black)](https://github.com/q9f/rlp.cr/search?l=crystal)
[![License](https://img.shields.io/github/license/q9f/rlp.cr.svg?color=black)](LICENSE)

a native library implementing `rlp` purely for the crystal language. `rlp` is ethereum's recursive length prefix used to encode arbitray data structures.

this library allows for rlp-encoding of:
* binary data (assumed encoded)
* boolean values (true, false)
* scalars (positive integers)
* string literals and characters
* arrays containing any of the above
* nested arrays containing any of the above

this library allows for decoding of:
* rlp-encoded data in binary format
* rlp-encoded data in hexadecimal string format

note, that decoded data is always binary as per ethereum's design rationale:

> _"RLP does not attempt to define any specific data types such as booleans, floats, doubles or even integers; instead, it simply exists to store structure, in the form of nested arrays, and leaves it up to the protocol to determine the meaning of the arrays"_

# installation

add the `rlp` library to your `shard.yml`

```yaml
dependencies:
  rlp:
    github: q9f/rlp.cr
    version: "~> 0.1"
```

# usage

```crystal
# import rlp
require "rlp"
```

this library exposes the following modules (in logical order):

* `Rlp`: core library exposing `encode` and `decode` logic
* `Rlp::Util`: a collection of utilities to ease the conversion between data types
* `Rlp::RecursiveArray`: is a data type alias allowing for arrays of unknown nesting depth

basic usage:

```crystal
# rlp-encode a string
rlp = Rlp.encode "A cat with a short string."
# => Bytes[154, 65, 32, 99, 97, 116, 32, 119, 105, 116, 104, 32, 97, 32, 115, 104, 111, 114, 116, 32, 115, 116, 114, 105, 110, 103, 46]

# (optionally) get a hex representation of the rlp-encoded data
hex = Rlp::Util.bin_to_hex rlp
# => "9a4120636174207769746820612073686f727420737472696e672e"

# decode the rlp data
bin = Rlp.decode hex
# => Bytes[65, 32, 99, 97, 116, 32, 119, 105, 116, 104, 32, 97, 32, 115, 104, 111, 114, 116, 32, 115, 116, 114, 105, 110, 103, 46]

# we expect a string, so we can try to convert it here
str = Rlp::Util.bin_to_str bin
# => "A cat with a short string."
```

# documentation

the full library documentation can be found here: [q9f.github.io/rlp.cr](https://q9f.github.io/rlp.cr/)

generate a local copy with:

```
crystal docs
```

# testing

the library is entirely specified through tests in `./spec`; run:

```bash
crystal spec --verbose
```

# understand

recursive length prefixes are used by the ethereum protocol to store arbitrary data structures, e.g., signed transactions, and is a fundamental serialization used by ethereum's networking protocol `devp2p` which implements `rlpx`, the _recursive length prefix transfer protocol_.

`rlp` can encode any data and data structure. the resulting data is a serialized byte-stream containing prefix bytes, header data, and actual data depending on the type and size of the encoded data.

```crystal
Rlp.encode [42, "eth"]
# => Bytes[197, 42, 131, 101, 116, 104]
```

deserialization of `rlp`-encoded byte-streams allows for recovering the underlying data structure. however, `rlp` is kept minimalistic in its specification and is therefore agnostic to the data types used in the structures.

```crystal
Rlp.decode Bytes[197, 42, 131, 101, 116, 104]
# => [Bytes[42], Bytes[101, 116, 104]]
```

It's up to applications using `rlp` to further specify protocols of decoding the actual data.

```crystal
decoded = Rlp.decode Bytes[197, 42, 131, 101, 116, 104]
protocol = [] of String | Int32 | BigInt
protocol << Rlp::Util.bin_to_int decoded[0]
protocol << Rlp::Util.bin_to_str decoded[1]
protocol
# => [42, "eth"]
```

# contribute

create a pull request, and make sure tests and linter passes.

this library with built with the help of the blog post by the mana team implementing [`rlp` in elixir](https://www.badykov.com/elixir/2018/05/06/rlp/) and coinmonks' [annotated version of the `rlp` specification](https://medium.com/coinmonks/data-structure-in-ethereum-episode-1-recursive-length-prefix-rlp-encoding-decoding-d1016832f919). ethereum classic's [`rlp` article](https://ethereumclassic.org/blog/2018-03-19-rlp/) allows for some sweet test cases.

license: apache license v2.0

contributors: [**@q9f**](https://github.com/q9f/)
