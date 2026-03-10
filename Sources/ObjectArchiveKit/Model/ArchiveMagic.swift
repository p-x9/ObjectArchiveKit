//
//  ArchiveMagic.swift
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/07
//  
//
import Foundation

public enum ArchiveMagic: String {
    case `default` = "!<arch>\u{0A}"
    case thin = "!<thin>\u{0A}"
    case big = "!<bout>\u{0A}"
}

extension ArchiveMagic {
    public static var layoutSize: Int { 8 /* SARMAG */ }
}
