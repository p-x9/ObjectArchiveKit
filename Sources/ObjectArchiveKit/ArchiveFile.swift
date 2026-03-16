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

    /// Parsed archive magic header.
    public let magic: ArchiveMagic

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

    public init(
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
        let magicData = try fileHandle.readData(
            offset: headerStartOffset,
            length: ArchiveMagic.layoutSize
        )
        guard let string = String(data: magicData, encoding: .utf8) else {
            throw ObjectArchiveKitError.invalidMagic
        }
        guard let magic = ArchiveMagic(rawValue: string) else {
            throw ObjectArchiveKitError.invalidMagic
        }

        /* Members */
        let members = try Self.parseArchiveMembers(
            fileHandle,
            startOffset: headerStartOffset,
            endOffset: endOffset
        )

        self.url = url
        self.magic = magic
        self.headerStartOffset = headerStartOffset
        self.endOffset = endOffset
        self.fileHandle = fileHandle
        self.members = members
    }
}

extension ArchiveFile {
    /// Archive layout kind inferred from member naming conventions.
    ///
    /// Pattern used by LLVM (`Archive.cpp`):
    /// - GNU: first `/` (optional symbol table), second `//` (optional string table).
    /// - BSD: first `__.SYMDEF` or `__.SYMDEF SORTED`; long names are `#1/<size>`.
    /// - COFF: first `/`, second `/`, third `//` (optional string table).
    ///
    /// Reference:
    /// https://github.com/llvm/llvm-project/blob/97572c1860efeeb97b5940927cee72081b61810a/llvm/lib/Object/Archive.cpp#L758
    public var kind: ArchiveKind  {
        guard let firstMember = members.first else {
            return .gnu
        }

        let firstName = firstMember.header.name

        if firstName == "__.SYMDEF" || firstName == "__.SYMDEF SORTED" {
            return .bsd
        }
        if firstName == "__.SYMDEF_64" {
            return .darwin64
        }

        if firstName.hasPrefix("#1/") {
            let resolvedName = firstMember.name(in: self)
            if resolvedName == "__.SYMDEF_64"
                || resolvedName == "__.SYMDEF_64 SORTED" {
                return .darwin64
            }
            return .bsd
        }

        let has64SymTable = (firstName == "/SYM64/")
        let defaultKind: ArchiveKind = has64SymTable ? .gnu64 : .gnu

        let name: String
        if firstName == "/" || has64SymTable {
            guard let nextName = members.dropFirst().first?.header.name else {
                return defaultKind
            }
            name = nextName
        } else {
            name = firstName
        }

        if name == "//" {
            return defaultKind
        }

        if name.hasPrefix("/") == false {
            return defaultKind
        }

        if name == "/" {
            return .coff
        }

        return defaultKind
    }
}

// MARK: - BSD

extension ArchiveFile {
    var _bsdSymbolsMember: ArchiveMember? {
        guard kind == .bsd else { return nil }
        guard let firstMember = members.first else { return nil }
        let name = firstMember.name(in: self)
        if name == "__.SYMDEF" || name == "__.SYMDEF SORTED" {
            return firstMember
        }
        return nil
    }

    public var bsdSymbolTable: ArchiveBSDSymbolTable? {
        guard let _bsdSymbolsMember else { return nil }
        return try? .load(
            from: _bsdSymbolsMember,
            in: self,
            is64Bit: false
        )
    }
}

// MARK: - Darwin64

extension ArchiveFile {
    var _darwin64SymbolsMember: ArchiveMember? {
        guard kind == .darwin64 else { return nil }
        guard let firstMember = members.first else { return nil }
        let name = firstMember.name(in: self)
        if name == "__.SYMDEF_64" || name == "__.SYMDEF_64 SORTED" {
            return firstMember
        }
        return nil
    }

    public var darwin64SymbolTable: ArchiveBSDSymbolTable? {
        guard let _darwin64SymbolsMember else { return nil }
        return try? .load(
            from: _darwin64SymbolsMember,
            in: self,
            is64Bit: true
        )
    }
}

// MARK: -  GNU
extension ArchiveFile {
    var _gnuSymbolsMember: ArchiveMember? {
        members.first(
            where: {
                $0.header.name == "/"
            }
        )
    }

    public var gnuSymbolTable: ArchiveGNUSymbolTable? {
        guard let _gnuSymbolsMember else { return nil }
        return try? .load(from: _gnuSymbolsMember, in: self)
    }
}

extension ArchiveFile {
    private var _gnuStringsMember: ArchiveMember? {
        guard [.gnu, .gnu64].contains(kind) else { return nil }
        return members.first(
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

// MARK: - COFF

extension ArchiveFile {
    private var _coffStringsMember: ArchiveMember? {
        guard kind == .coff else { return nil }
        return members.first(
            where: {
                $0.header.name == "//"
            }
        )
    }

    public var coffStrings: UnicodeStrings<UTF8>? {
        guard let _coffStringsMember else { return nil }
        guard let offset = _coffStringsMember.dataOffset(in: self) else {
            return nil
        }
        let size = _coffStringsMember.header.size
        let slice = try? fileHandle.fileSlice(
            offset: offset + headerStartOffset,
            length: size
        )
        guard let slice else { return nil }
        return .init(
            source: slice,
            offset: offset,
            size: size,
            isSwapped: false
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
