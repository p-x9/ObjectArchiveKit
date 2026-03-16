import XCTest
@testable import ObjectArchiveKit

final class ObjectArchiveKitTests: XCTestCase {

    private var archive: ArchiveFile!

    override func setUp() {
        let path = ""
        let url = URL(fileURLWithPath: path)
        archive = try! ArchiveFile(url: url)
    }
}

extension ObjectArchiveKitTests {
    func testArchive() {
        print("Magic:", archive.magic)
        print("Kind:", archive.kind)
    }

    func testMembers() {
        for (i, member) in archive.members.enumerated() {
            print("[\(i)]", member.name(in: archive))
            print(" offset", member.offset)
            print(" size", member.header.size)
        }
    }
}

extension ObjectArchiveKitTests {
    func testGNUSymbols() throws {
        guard let symbolTable = archive.gnuSymbolTable else {
            return
        }
        print("count: \(symbolTable.count)")
        if let offsets = symbolTable.offsets(in: archive) {
            print("offset:")
            for (i, offset) in offsets.enumerated() {
                print("", i, offset)
            }
        }
        if let names = try symbolTable.names(in: archive) {
            print("names:")
            for (i, name) in names.enumerated() {
                print("", i, name.string)
            }
        }
    }

    func testGNUStrings() {
        guard let strings = archive.gnuStrings else {
            return
        }
        for string in strings {
            print(string.offset, string.string)
        }
    }
}

extension ObjectArchiveKitTests {
    func testBSDSymbols() throws {
        guard let symbolTable = archive.bsdSymbolTable else {
            return
        }
        print("count: \(symbolTable.count)")
        print("isSorted: \(symbolTable.isSorted(in: archive))")
        for symbol in try symbolTable.entries(in: archive) {
            let name = try symbolTable.name(for: symbol, in: archive)
            print(name ?? "unknown", symbol.stringOffset, symbol.headerOffset)
        }
    }

    func testDarwin64Symbols() throws {
        guard let symbolTable = archive.darwin64SymbolTable else {
            return
        }
        print("count: \(symbolTable.count)")
        print("isSorted: \(symbolTable.isSorted(in: archive))")
        for symbol in try symbolTable.entries(in: archive) {
            let name = try symbolTable.name(for: symbol, in: archive)
            print(name ?? "unknown", symbol.stringOffset, symbol.headerOffset)
        }
    }
}
