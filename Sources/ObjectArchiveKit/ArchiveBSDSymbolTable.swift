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
    public func isSorted(in archive: ArchiveFile) -> Bool {
        member.name(in: archive).hasSuffix("SORTED")
    }
}

extension ArchiveBSDSymbolTable {
    public func entries32(
        in archive: ArchiveFile
    ) throws -> DataSequence<ArchiveRanLib32>? {
        guard !is64Bit else { return nil }
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }
        return archive.fileHandle.readDataSequence(
            offset: numericCast(offset + MemoryLayout<UInt32>.size),
            numberOfElements: metadata.count
        )
    }

    public func entries64(
        in archive: ArchiveFile
    ) throws -> DataSequence<ArchiveRanLib64>? {
        guard is64Bit else { return nil }
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }
        return archive.fileHandle.readDataSequence(
            offset: numericCast(offset + MemoryLayout<UInt64>.size),
            numberOfElements: metadata.count
        )
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
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }

        let slice = try archive.fileHandle.fileSlice(
            offset: offset + metadata.stringTableOffset + archive.headerStartOffset,
            length: metadata.stringTableSize
        )
        return .init(
            source: slice,
            offset: metadata.stringTableOffset,
            size: metadata.stringTableSize,
            isSwapped: false
        )
    }
}

extension ArchiveBSDSymbolTable {
    static func load(
        from member: ArchiveMember,
        in archive: ArchiveFile,
        is64Bit: Bool
    ) throws -> ArchiveBSDSymbolTable? {
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }

        if is64Bit {
            let ranlibByteSize: UInt64 = try archive.fileHandle.read(
                offset: offset + archive.headerStartOffset
            )
            let stringTableSize: UInt64 = try archive.fileHandle.read(
                offset: offset
                + MemoryLayout<UInt64>.size
                + numericCast(ranlibByteSize)
                + archive.headerStartOffset
            )
            let metadata: Metadata = .init(
                count: numericCast(ranlibByteSize) / ArchiveRanLib64.layoutSize,
                ranlibByteSize: numericCast(ranlibByteSize),
                stringTableOffset: numericCast(
                    MemoryLayout<UInt64>.size
                    + numericCast(ranlibByteSize)
                    + MemoryLayout<UInt64>.size
                ),
                stringTableSize: numericCast(stringTableSize)
            )
            return .init(member: member, metadata: metadata, is64Bit: is64Bit)
        } else {
            let ranlibByteSize: UInt32 = try archive.fileHandle.read(
                offset: offset + archive.headerStartOffset
            )
            let stringTableSize: UInt32 = try archive.fileHandle.read(
                offset: offset
                + MemoryLayout<UInt32>.size
                + numericCast(ranlibByteSize)
                + archive.headerStartOffset
            )
            let metadata: Metadata = .init(
                count: numericCast(ranlibByteSize) / ArchiveRanLib32.layoutSize,
                ranlibByteSize: numericCast(ranlibByteSize),
                stringTableOffset: numericCast(
                    MemoryLayout<UInt32>.size
                    + numericCast(ranlibByteSize)
                    + MemoryLayout<UInt32>.size
                ),
                stringTableSize: numericCast(stringTableSize)
            )
            return .init(member: member, metadata: metadata, is64Bit: is64Bit)
        }
    }
}
