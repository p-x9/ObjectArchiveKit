//
//  ArchiveGNUSymbolTable.swift
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/08
//  
//

import Foundation
@_spi(Core) import BinaryParseSupport

public typealias ArchiveCOFFLegacySymbolTable = ArchiveGNUSymbolTable

public struct ArchiveGNUSymbolTable: Sendable {
    public let member: ArchiveMember
    public let count: Int
}

extension ArchiveGNUSymbolTable {
    public func offsets(
        in archive: ArchiveFile
    ) -> DataSequence<UInt32>? {
        guard var offset = member.dataOffset(in: archive) else {
            return nil
        }
        offset += MemoryLayout<UInt32>.size

        return archive.fileHandle
            .readDataSequence(
                offset: numericCast(offset + archive.headerStartOffset),
                numberOfElements: count,
                swapHandler: { data in
                    if Endian.current == .little {
                        data = data.byteSwapped(UInt32.self)
                    }
                }
            )
    }

    public func names(
        in archive: ArchiveFile
    ) throws -> UnicodeStrings<UTF8>? {
        guard let baseOffset = member.dataOffset(in: archive) else {
            return nil
        }
        var offset = baseOffset
        offset += MemoryLayout<UInt32>.size
        offset += MemoryLayout<UInt32>.size * count

        let size = member.header.size - (offset - baseOffset)

        let slice = try archive.fileHandle.fileSlice(
            offset: offset,
            length: size
        )

        return .init(
            source: slice,
            offset: offset,
            size: size,
            isSwapped: false
        )
    }
}

extension ArchiveGNUSymbolTable {
    static func load(
        from member: ArchiveMember,
        in archive: ArchiveFile
    ) throws -> ArchiveGNUSymbolTable? {
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }
        let count: UInt32 = try archive.fileHandle.read(
            offset: offset + archive.headerStartOffset
        )
        return .init(
            member: member,
            count: numericCast(count.bigEndian)
        )
    }
}
