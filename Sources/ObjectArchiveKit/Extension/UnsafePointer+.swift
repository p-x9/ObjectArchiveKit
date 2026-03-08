//
//  UnsafePointer+.swift
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/07
//  
//

import Foundation

extension UnsafePointer where Pointee: FixedWidthInteger {
    func findNullTerminator() -> UnsafePointer<Pointee> {
        findTerminator(0)
    }

    public func findTerminator(
        _ terminator: Pointee = 0
    ) -> UnsafePointer<Pointee> {
        var ptr = self
        while ptr.pointee != terminator {
            ptr = ptr.advanced(by: 1)
        }
        return ptr
    }

    public func readString<Encoding: _UnicodeEncoding>(
        as encoding: Encoding.Type,
        terminator: Encoding.CodeUnit = 0
    ) -> (String, Int) where Pointee == Encoding.CodeUnit {
        let terminatorPointer = findTerminator(terminator)
        let length = self.distance(to: terminatorPointer)
        let offset = length * MemoryLayout<Pointee>.size + MemoryLayout<Pointee>.size

        let buffer = UnsafeBufferPointer(start: self, count: length)
        let string = String(decoding: buffer, as: Encoding.self)

        return (string, offset)
    }
}
