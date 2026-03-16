//
//  ArchiveRanLib.swift
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/16
//  
//

import ObjectArchiveKitC

public protocol ArchiveRanLibProtocol {
    var stringOffset: Int { get }
    var headerOffset: Int { get }
}

public struct ArchiveRanLib32: LayoutWrapper, Sendable {
    public typealias Layout = ranlib32

    public var layout: Layout
}

public struct ArchiveRanLib64: LayoutWrapper, Sendable {
    public typealias Layout = ranlib64

    public var layout: Layout
}

extension ArchiveRanLib32: ArchiveRanLibProtocol {
    public var stringOffset: Int { numericCast(layout.ran_strx) }
    public var headerOffset: Int { numericCast(layout.ran_off) }
}

extension ArchiveRanLib64: ArchiveRanLibProtocol {
    public var stringOffset: Int { numericCast(layout.ran_strx) }
    public var headerOffset: Int { numericCast(layout.ran_off) }
}
