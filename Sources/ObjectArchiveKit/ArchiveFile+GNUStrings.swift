//
//  ArchiveFile+GNUStrings.swift
//  MachOKit
//
//  Created by p-x9 on 2026/03/07
//
//

import Foundation
@_spi(Core) import BinaryParseSupport

extension ArchiveFile {
    public struct GNUStrings: StringTable {
        public typealias Encoding = UTF8

        typealias FileSlice = File.FileSlice

        private let fileSlice: FileSlice

        /// file offset of string table start
        public let offset: Int

        /// size of string table
        public let size: Int

        init(
            fileSlice: FileSlice,
            offset: Int,
            size: Int
        ) {
            self.fileSlice = fileSlice
            self.offset = offset
            self.size = size
        }

        public func makeIterator() -> Iterator {
            .init(fileSlice: fileSlice)
        }
    }
}

extension ArchiveFile.GNUStrings {
    public func string(at offset: Int) -> StringTableEntry? {
        guard 0 <= offset, offset < fileSlice.size else { return nil }
        let (string, _) = UnsafeRawPointer(fileSlice.ptr)
            .advanced(by: offset)
            .assumingMemoryBound(to: UInt8.self)
            .readString(
                as: UTF8.self,
                terminator: 0x0a  // \n
            )
        return unsafeBitCast(
            (string, offset),
            to: Element.self
        )
    }
}

extension ArchiveFile.GNUStrings {
    public var data: Data? {
        try? fileSlice.readAllData()
    }
}

extension ArchiveFile.GNUStrings {
    public struct Iterator: IteratorProtocol {
        public typealias Element = StringTableEntry

        private let fileSlice: FileSlice
        private let tableSize: Int

        private var nextOffset: Int

        init(fileSlice: FileSlice) {
            self.fileSlice = fileSlice
            self.tableSize = fileSlice.size
            self.nextOffset = 0
        }

        public mutating func next() -> Element? {
            guard nextOffset < tableSize else { return nil }

            var (string, length) = UnsafeRawPointer(fileSlice.ptr)
                .advanced(by: nextOffset)
                .assumingMemoryBound(to: UInt8.self)
                .readString(
                    as: UTF8.self,
                    terminator: 0x0a  // \n
                )

            defer {
                nextOffset += length
            }

            if string.hasSuffix("/") {
                string = String(string.dropLast())
            }

            return unsafeBitCast(
                (string, nextOffset),
                to: Element.self
            )
        }
    }
}
