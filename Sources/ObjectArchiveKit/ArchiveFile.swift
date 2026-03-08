//
//  ArchiveFile.swift
//  MachOKit
//
//  Created by p-x9 on 2026/03/05.
//

import Foundation
#if compiler(>=6.0) || (compiler(>=5.10) && hasFeature(AccessLevelOnImport))
internal import FileIO
internal import FileIOBinary
#else
@_implementationOnly import FileIO
@_implementationOnly import FileIOBinary
#endif
import ObjectArchiveKitC

/// A representation of a Unix `ar` archive such as a static library (`.a`).
///
/// `ArchiveFile` parses the archive container and exposes its members.
/// Mach-O members can then be loaded through ``machOFiles()``.
public final class ArchiveFile {
    typealias File = MemoryMappedFile

    /// The file URL of the archive.
    public let url: URL

    /// File offset at which the archive header begins.
    public let headerStartOffset: Int
    let endOffset: Int

    let fileHandle: File

    /// The parsed members contained in the archive.
    public let members: [ArchiveMember]

    /// Creates an `ArchiveFile` by reading and parsing the archive at the specified file URL.
    ///
    /// - Parameter url: The file URL of the archive.
    /// - Throws: `MachOKitError.invalidArchiveMagic` when the file is not an `ar` archive,
    ///           or `MachOKitError.invalidArchiveHeader` when a member header is malformed.
    public convenience init(url: URL) throws {
        try self.init(url: url, headerStartOffset: 0)
    }

    init(
        url: URL,
        headerStartOffset: Int,
        size: Int? = nil
    ) throws {
        /* File */
        let fileHandle = try File.open(
            url: url,
            isWritable: false
        )
        let fileSize = fileHandle.size
        let endOffset = min(
            fileSize,
            headerStartOffset + (size ?? (fileSize - headerStartOffset))
        )

        /* Magic */
        let magic = try fileHandle.readData(
            offset: headerStartOffset,
            length: ArchiveMagic.layoutSize
        )
        guard let string = String(data: magic, encoding: .utf8) else {
            throw ObjectArchiveKitError.invalidMagic
        }
        guard ArchiveMagic(rawValue: string) != nil else {
            throw ObjectArchiveKitError.invalidMagic
        }

        /* Members */
        let members = try Self.parseArchiveMembers(
            fileHandle,
            startOffset: headerStartOffset,
            endOffset: endOffset
        )

        self.url = url
        self.headerStartOffset = headerStartOffset
        self.endOffset = endOffset
        self.fileHandle = fileHandle
        self.members = members
    }
}

// MARK: -  GNU string table
extension ArchiveFile {
    var _gnuStringsMember: ArchiveMember? {
        members.first(
            where: {
                $0.header.name == "//"
            }
        )
    }

    public var gnuStrings: GNUStrings? {
        guard let _gnuStringsMember else { return nil }
        guard let offset = _gnuStringsMember.dataOffset(in: self) else {
            return nil
        }
        let size = _gnuStringsMember.header.size
        let slice = try? fileHandle.fileSlice(
            offset: offset + headerStartOffset,
            length: size
        )
        guard let slice else { return nil }
        return .init(
            fileSlice: slice,
            offset: offset,
            size: size
        )
    }
}

// MARK: Internal

extension ArchiveFile {
    private static func parseArchiveMembers(
        _ fileHandle: File,
        startOffset: Int,
        endOffset: Int
    ) throws -> [ArchiveMember] {
        guard startOffset + ArchiveMagic.layoutSize <= endOffset else {
            throw ObjectArchiveKitError.invalidHeader
        }

        var offset = startOffset + ArchiveMagic.layoutSize
        var members = [ArchiveMember]()

        while offset < endOffset {
            guard offset + ArchiveMemberHeader.layoutSize <= endOffset else {
                throw ObjectArchiveKitError.invalidHeader
            }
            let header: ArchiveMemberHeader = try fileHandle.read(
                offset: offset
            )
            guard header.isValid else {
                throw ObjectArchiveKitError.invalidHeader
            }
            members.append(
                .init(
                    header: header,
                    offset: offset
                )
            )
            offset += ArchiveMemberHeader.layoutSize
            offset += header.size

            // alignment
            if header.size.isMultiple(of: 2) == false {
                offset += 1
            }
        }

        return members
    }
}
