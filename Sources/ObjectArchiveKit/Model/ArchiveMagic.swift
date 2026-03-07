//
//  ArchiveMagic.swift
//  ObjectArchiveKit
//
//  Created by p-x9 on 2026/03/07
//  
//
import Foundation

public enum ArchiveMagic: String {
    case `default` = "!<arch>\012"
    case thin = "!<thin>\012"
    case big = "!<bout>\012"
}

extension ArchiveMagic {
    public static var layoutSize: Int { 8 }
}
