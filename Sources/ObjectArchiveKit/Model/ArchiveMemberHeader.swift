//
//  ArchiveMemberHeader.swift
//  MachOKit
//
//  Created by p-x9 on 2026/03/05
//
//

import Foundation
import ObjectArchiveKitC

public struct ArchiveMemberHeader: LayoutWrapper, Sendable {
    public typealias Layout = ar_hdr

    public var layout: Layout
}

extension ArchiveMemberHeader {
    public var name: String {
        String(tuple: layout.ar_name)
            .trimmingCharacters(in: .whitespaces)
    }

    public var date: String {
        String(tuple: layout.ar_date)
            .trimmingCharacters(in: .whitespaces)
    }

    public var uid: String {
        String(tuple: layout.ar_uid)
            .trimmingCharacters(in: .whitespaces)
    }

    public var gid: String {
        String(tuple: layout.ar_gid)
            .trimmingCharacters(in: .whitespaces)
    }

    public var mode: String {
        String(tuple: layout.ar_mode)
            .trimmingCharacters(in: .whitespaces)
    }

    public var _size: String {
        String(tuple: layout.ar_size)
            .trimmingCharacters(in: .whitespaces)
    }

    public var size: Int {
        Int(_size)!
    }

    public var fmag: String {
        String(tuple: layout.ar_fmag)
            .trimmingCharacters(in: .whitespaces)
    }
}

extension ArchiveMemberHeader {
    public var isValid: Bool {
        guard fmag == ObjectArchiveKitC.ARFMAG,
              Int(_size) != nil else {
            return false
        }
        return true
    }
}

#if swift(>=5.11)
extension String {
    fileprivate init<each T: FixedWidthInteger>(tuple: (repeat each T)) {
        self = withUnsafePointer(to: tuple) {
            let size = MemoryLayout<(repeat each T)>.size
            let data = Data(
                bytes: UnsafeRawPointer($0)
                    .assumingMemoryBound(to: UInt8.self),
                count: size
            ) + [0]
            return String(cString: data) ?? ""
        }
    }
}
#else
extension String {
    fileprivate typealias CCharTuple16 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

    fileprivate init(tuple: CCharTuple16) {
        self = withUnsafePointer(to: tuple) {
            let size = MemoryLayout<CCharTuple16>.size
            let data = Data(bytes: $0, count: size) + [0]
            return String(cString: data) ?? ""
        }
    }
}

extension String {
    fileprivate typealias CCharTuple12 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

    fileprivate init(tuple: CCharTuple12) {
        self = withUnsafePointer(to: tuple) {
            let size = MemoryLayout<CCharTuple12>.size
            let data = Data(bytes: $0, count: size) + [0]
            return String(cString: data) ?? ""
        }
    }
}

extension String {
    fileprivate typealias CCharTuple8 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

    fileprivate init(tuple: CCharTuple8) {
        self = withUnsafePointer(to: tuple) {
            let size = MemoryLayout<CCharTuple8>.size
            let data = Data(bytes: $0, count: size) + [0]
            return String(cString: data) ?? ""
        }
    }
}

extension String {
    fileprivate typealias CCharTuple6 = (CChar, CChar, CChar, CChar, CChar, CChar)

    fileprivate init(tuple: CCharTuple6) {
        self = withUnsafePointer(to: tuple) {
            let size = MemoryLayout<CCharTuple6>.size
            let data = Data(bytes: $0, count: size) + [0]
            return String(cString: data) ?? ""
        }
    }
}

extension String {
    fileprivate typealias CCharTuple10 = (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)

    fileprivate init(tuple: CCharTuple10) {
        self = withUnsafePointer(to: tuple) {
            let size = MemoryLayout<CCharTuple10>.size
            let data = Data(bytes: $0, count: size) + [0]
            return String(cString: data) ?? ""
        }
    }
}

extension String {
    fileprivate typealias CCharTuple2 = (CChar, CChar)

    fileprivate init(tuple: CCharTuple2) {
        self = withUnsafePointer(to: tuple) {
            let size = MemoryLayout<CCharTuple2>.size
            let data = Data(bytes: $0, count: size) + [0]
            return String(cString: data) ?? ""
        }
    }
}
#endif
