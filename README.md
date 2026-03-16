# ObjectArchiveKit

A Swift library for parsing Unix `ar` archives (for example static libraries like `.a`) and reading member/symbol metadata.

The parser supports multiple archive layouts used by toolchains such as GNU, BSD, Darwin, and COFF.

<!-- # Badges -->

[![Github issues](https://img.shields.io/github/issues/p-x9/ObjectArchiveKit)](https://github.com/p-x9/ObjectArchiveKit/issues)
[![Github forks](https://img.shields.io/github/forks/p-x9/ObjectArchiveKit)](https://github.com/p-x9/ObjectArchiveKit/network/members)
[![Github stars](https://img.shields.io/github/stars/p-x9/ObjectArchiveKit)](https://github.com/p-x9/ObjectArchiveKit/stargazers)
[![Github top language](https://img.shields.io/github/languages/top/p-x9/ObjectArchiveKit)](https://github.com/p-x9/ObjectArchiveKit/)

## Features

- Parse archive magic headers (`!<arch>\n`, `!<thin>\n`, `!<bout>\n`)
- Enumerate archive members and resolve member names (including long-name formats)
- Detect archive kind (`gnu`, `gnu64`, `bsd`, `darwin64`, `coff`)
- Read GNU symbol table (`/`) and string table (`//`)
- Read BSD/Darwin64 symbol tables (`__.SYMDEF*`) and map symbols to members
- Read COFF string table entries

## Installation

### Swift Package Manager

Add `ObjectArchiveKit` to your `Package.swift` dependencies.

```swift
dependencies: [
    .package(url: "https://github.com/p-x9/ObjectArchiveKit.git", branch: "main")
]
```

Then add the product to your target.

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "ObjectArchiveKit", package: "ObjectArchiveKit")
        ]
    )
]
```

## Usage

### Load from file

```swift
import Foundation
import ObjectArchiveKit

let url = URL(fileURLWithPath: "/path/to/libSomething.a")
let archive = try ArchiveFile(url: url)

print("Magic:", archive.magic)
print("Kind:", archive.kind)
print("Members:", archive.members.count)
```

### Enumerate members

```swift
for (index, member) in archive.members.enumerated() {
    print("[\(index)]", member.name(in: archive))
    print("  offset:", member.offset)
    print("  size:", member.header.size)
}
```

### Read symbol tables

```swift
switch archive.kind {
case .gnu, .gnu64:
    if let table = archive.gnuSymbolTable {
        print("GNU symbol count:", table.count)
        if let names = try table.names(in: archive) {
            for entry in names {
                print(entry.offset, entry.string)
            }
        }
    }

case .bsd:
    if let table = archive.bsdSymbolTable {
        print("BSD symbol count:", table.count)
        for symbol in try table.entries(in: archive) {
            let name = try table.name(for: symbol, in: archive) ?? "unknown"
            print(name, symbol.stringOffset, symbol.headerOffset)
        }
    }

case .darwin64:
    if let table = archive.darwin64SymbolTable {
        print("Darwin64 symbol count:", table.count)
        for symbol in try table.entries(in: archive) {
            let name = try table.name(for: symbol, in: archive) ?? "unknown"
            print(name, symbol.stringOffset, symbol.headerOffset)
        }
    }

case .coff:
    if let strings = archive.coffStrings {
        for entry in strings {
            print(entry.offset, entry.string)
        }
    }
}
```

### Parse an archive region in a larger file

If an archive starts at a non-zero offset, use the designated initializer:

```swift
let archive = try ArchiveFile(
    url: url,
    headerStartOffset: 0x1000,
    size: 0x20000
)
```

## Example Codes

Basic print-style examples are available in:

- [ObjectArchiveKitTests](./Tests/ObjectArchiveKitTests/ObjectArchiveKitTests.swift)

## License

This repository currently does not include a `LICENSE` file.
