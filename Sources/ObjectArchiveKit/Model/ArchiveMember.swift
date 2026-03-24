//
//  ArchiveMember.swift
//  MachOKit
//
//  Created by p-x9 on 2026/03/06
//
//

import Foundation
#if compiler(>=6.0) || (compiler(>=5.10) && hasFeature(AccessLevelOnImport))
internal import FileIO
internal import FileIOBinary
#else
@_implementationOnly import FileIO
@_implementationOnly import FileIOBinary
#endif

public struct ArchiveMember: Sendable {
    public let header: ArchiveMemberHeader
    public let offset: Int
}

extension ArchiveMember {
    // ref: https://github.com/llvm/llvm-project/blob/97572c1860efeeb97b5940927cee72081b61810a/llvm/lib/Object/Archive.cpp#L243
    public func name(in archive: ArchiveFile) -> String {
        let rawName = header.name
        // Check if it's a special name.
        if rawName == "/" || rawName == "//" {
            return rawName
        }

        if rawName.hasPrefix("#1/"),
           let nameLength = Int(rawName.dropFirst(3).trimmingCharacters(in: .whitespaces)),
           let payloadOffset = payloadOffset(in: archive),
           nameLength <= header.size,
           let nameData = try? archive.fileHandle.readData(
            offset: payloadOffset + archive.headerStartOffset,
            length: nameLength
           ),
           let resolvedName = Self.decodedName(from: nameData) {
            return resolvedName
        }

        if rawName.hasPrefix("/"),
           rawName.dropFirst().allSatisfy(\.isNumber),
           let offset = Int(rawName.dropFirst()),
           let strings: any StringTable = archive.gnuStrings ?? archive.coffStrings,
           let resolvedName = strings.string(at: offset)?.string {
            if resolvedName.hasSuffix("/") {
                return String(resolvedName.dropLast())
            }
            return resolvedName
        }

        if rawName.hasSuffix("/") {
            return String(rawName.dropLast())
        }
        return rawName
    }
}

extension ArchiveMember {
    public func dataOffset(in archive: ArchiveFile) -> Int? {
        guard let payloadOffset = payloadOffset(in: archive) else {
            return nil
        }
        let rawName = header.name
        if rawName.hasPrefix("#1/") {
            let lengthText = rawName.dropFirst(3).trimmingCharacters(in: .whitespaces)
            guard let nameLength = Int(lengthText), nameLength <= header.size else {
                return nil
            }
            return payloadOffset + nameLength
        }
        return payloadOffset
    }
}

private extension ArchiveMember {
    func payloadOffset(in archive: ArchiveFile) -> Int? {
        let payloadOffset = offset + ArchiveMemberHeader.layoutSize
        guard payloadOffset + header.size <= archive.endOffset else {
            return nil
        }
        return payloadOffset
    }

    static func decodedName(from data: Data) -> String? {
        let content = data.prefix { $0 != 0 }
        guard content.isEmpty == false else {
            return nil
        }
        return String(data: content, encoding: .utf8)
    }
}
