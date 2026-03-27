//
//  ArchiveCOFFSymbolTable.swift
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/25
//  
//

import Foundation
@_spi(Core) import BinaryParseSupport

public struct ArchiveCOFFSymbolTable: Sendable {
    public let member: ArchiveMember
    public let metadata: Metadata
}

extension ArchiveCOFFSymbolTable {
    public struct Metadata: Sendable {
        public let numberOfMembers: Int /* uint32 */
        public let numberOfSymbols: Int /* uint32 */
        public let indicesOffset: Int
        public let stringTableOffset: Int
    }
}

extension ArchiveCOFFSymbolTable {
    public func offsets(
        in archive: ArchiveFile
    ) -> DataSequence<UInt32>? {
        guard let offset = archiveOffset(
            in: archive,
            additionalOffset: MemoryLayout<UInt32>.size
        ) else {
            return nil
        }

        return archive.fileHandle
            .readDataSequence(
                offset: numericCast(offset + archive.headerStartOffset),
                numberOfElements: metadata.numberOfMembers
            )
    }

    /// An array of 1-based indexes (unsigned short ) that map symbol names to archive member offsets
    ///
    /// The number n is equal to the Number of Symbols field.
    /// For each symbol that is named in the string table, the corresponding element in the Indices array gives an index into the offsets array.
    public func indices(
        in archive: ArchiveFile
    ) -> DataSequence<UInt16>? {
        guard let offset = archiveOffset(
            in: archive,
            additionalOffset: metadata.indicesOffset
        ) else {
            return nil
        }
        return archive.fileHandle
            .readDataSequence(
                offset: numericCast(offset + archive.headerStartOffset),
                numberOfElements: metadata.numberOfSymbols
            )
    }

    public func names(
        in archive: ArchiveFile
    ) throws -> UnicodeStrings<UTF8>? {
        guard let offset = archiveOffset(
            in: archive,
            additionalOffset: metadata.stringTableOffset
        ) else {
            return nil
        }

        // Ensure the string table lies within the member and has a positive length.
        guard metadata.stringTableOffset <= member.header.size else {
            return nil
        }
        let length = member.header.size - metadata.stringTableOffset
        guard length > 0 else {
            return nil
        }

        let slice = try archive.fileHandle.fileSlice(
            offset: offset + archive.headerStartOffset,
            length: length
        )
        return .init(
            source: slice,
            offset: metadata.stringTableOffset,
            size: slice.size,
            isSwapped: false
        )
    }
}

// MARK: Load

extension ArchiveCOFFSymbolTable {
    static func load(
        from member: ArchiveMember,
        in archive: ArchiveFile
    ) throws -> ArchiveCOFFSymbolTable? {
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }
        let baseOffset = offset + archive.headerStartOffset

        let numberOfMembers: UInt32 = try archive.fileHandle.read(offset: baseOffset)
        let numberOfSymbols: UInt32 = try archive.fileHandle.read(
            offset: baseOffset
            + MemoryLayout<UInt32>.size
            + numericCast(numberOfMembers) * MemoryLayout<UInt32>.size
        )

        let indicesOffset = MemoryLayout<UInt32>.size
        + numericCast(numberOfMembers) * MemoryLayout<UInt32>.size
        + MemoryLayout<UInt32>.size

        let stringTableOffset = indicesOffset
        + numericCast(numberOfSymbols) * MemoryLayout<UInt16>.size

        return .init(
            member: member,
            metadata: .init(
                numberOfMembers: numericCast(numberOfMembers),
                numberOfSymbols: numericCast(numberOfSymbols),
                indicesOffset: indicesOffset,
                stringTableOffset: stringTableOffset
            )
        )
    }
}

// MARK: Private

extension ArchiveCOFFSymbolTable {
    private func archiveOffset(
        in archive: ArchiveFile,
        additionalOffset: Int = 0
    ) -> Int? {
        guard let offset = member.dataOffset(in: archive) else {
            return nil
        }
        return offset + additionalOffset
    }
}
