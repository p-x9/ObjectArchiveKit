//
//  ArchiveBSDSymbolTable.swift
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/13.
//
//

import Foundation
@_spi(Core) import BinaryParseSupport

public struct ArchiveBSDSymbolTable: Sendable {
    public let member: ArchiveMember
    public let metadata: Metadata
    public let is64Bit: Bool
}

extension ArchiveBSDSymbolTable {
    public struct Metadata: Sendable {
        public let count: Int
        public let ranlibByteSize: Int
        public let stringTableOffset: Int
        public let stringTableSize: Int
    }
}

extension ArchiveBSDSymbolTable {
    public var count: Int {
        metadata.count
    }

    public func isSorted(in archive: ArchiveFile) -> Bool {
        member.name(in: archive).hasSuffix("SORTED")
    }
}

extension ArchiveBSDSymbolTable {
    public func entries32(
        in archive: ArchiveFile
    ) throws -> DataSequence<ArchiveRanLib32>? {
        guard !is64Bit else { return nil }
        return try readEntries(in: archive, as: ArchiveRanLib32.self)
    }

    public func entries64(
        in archive: ArchiveFile
    ) throws -> DataSequence<ArchiveRanLib64>? {
        guard is64Bit else { return nil }
        return try readEntries(in: archive, as: ArchiveRanLib64.self)
    }

    public func entries(
        in archive: ArchiveFile
    ) throws -> [any ArchiveRanLibProtocol] {
        if is64Bit, let entries64 = try entries64(in: archive) {
            Array(entries64)
        } else if let entries32 = try entries32(in: archive) {
            Array(entries32)
        } else {
            []
        }
    }
}

extension ArchiveBSDSymbolTable {
    public func names(
        in archive: ArchiveFile
    ) throws -> UnicodeStrings<UTF8>? {
        guard metadata.stringTableSize > 0 else {
            return nil
        }
        guard let offset = archiveOffset(
            in: archive,
            additionalOffset: metadata.stringTableOffset
        ) else {
            return nil
        }

        let slice = try archive.fileHandle.fileSlice(
            offset: offset + archive.headerStartOffset,
            length: metadata.stringTableSize
        )
        return .init(
            source: slice,
            offset: metadata.stringTableOffset,
            size: metadata.stringTableSize,
            isSwapped: false
        )
    }

    public func name(
        for symbol: some ArchiveRanLibProtocol,
        in archive: ArchiveFile
    ) throws -> String? {
        guard let names = try names(in: archive) else { return nil }
        return names.string(at: symbol.stringOffset)?.string
    }
}

extension ArchiveBSDSymbolTable {
    public func member(
        for symbol: some ArchiveRanLibProtocol,
        in archive: ArchiveFile
    ) throws -> ArchiveMember? {
        let header: ArchiveMemberHeader = try archive.fileHandle
            .read(offset: symbol.headerOffset + archive.headerStartOffset)
        return .init(
            header: header,
            offset: symbol.headerOffset
        )
    }
}

// MARK: Load

extension ArchiveBSDSymbolTable {
    static func load(
        from member: ArchiveMember,
        in archive: ArchiveFile,
        is64Bit: Bool
    ) throws -> ArchiveBSDSymbolTable? {
        if is64Bit {
            return try load(
                from: member,
                in: archive,
                wordType: UInt64.self,
                entrySize: ArchiveRanLib64.layoutSize,
                is64Bit: true
            )
        } else {
            return try load(
                from: member,
                in: archive,
                wordType: UInt32.self,
                entrySize: ArchiveRanLib32.layoutSize,
                is64Bit: false
            )
        }
    }
}

// MARK: Private

extension ArchiveBSDSymbolTable {
    private var byteCountFieldSize: Int {
        is64Bit ? MemoryLayout<UInt64>.size : MemoryLayout<UInt32>.size
    }

    private var entriesOffset: Int {
        byteCountFieldSize
    }

    private func archiveOffset(
        in archive: ArchiveFile,
        additionalOffset: Int = 0
    ) -> Int? {
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }
        return offset + additionalOffset
    }

    private func readEntries<Entry>(
        in archive: ArchiveFile,
        as _: Entry.Type
    ) throws -> DataSequence<Entry>? where Entry: ArchiveRanLibProtocol & LayoutWrapper {
        guard let offset = archiveOffset(
            in: archive,
            additionalOffset: entriesOffset
        ) else {
            return nil
        }
        return archive.fileHandle.readDataSequence(
            offset: numericCast(offset + archive.headerStartOffset),
            numberOfElements: metadata.count
        )
    }

    private static func makeMetadata<Word: FixedWidthInteger>(
        ranlibByteSize: Word,
        stringTableSize: Word,
        entrySize: Int
    ) -> Metadata {
        let ranlibByteSize: Int = numericCast(ranlibByteSize)
        return .init(
            count: ranlibByteSize / entrySize,
            ranlibByteSize: ranlibByteSize,
            stringTableOffset: MemoryLayout<Word>.size
                + ranlibByteSize
                + MemoryLayout<Word>.size,
            stringTableSize: numericCast(stringTableSize)
        )
    }

    private static func load<Word: FixedWidthInteger>(
        from member: ArchiveMember,
        in archive: ArchiveFile,
        wordType: Word.Type,
        entrySize: Int,
        is64Bit: Bool
    ) throws -> ArchiveBSDSymbolTable? {
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }

        let baseOffset = offset + archive.headerStartOffset
        let ranlibByteSize: Word = try archive.fileHandle.read(offset: baseOffset)
        let stringTableSizeOffset = baseOffset
            + MemoryLayout<Word>.size
            + numericCast(ranlibByteSize)
        let stringTableSize: Word = try archive.fileHandle.read(
            offset: stringTableSizeOffset
        )
        let metadata = makeMetadata(
            ranlibByteSize: ranlibByteSize,
            stringTableSize: stringTableSize,
            entrySize: entrySize
        )
        return .init(member: member, metadata: metadata, is64Bit: is64Bit)
    }
}
