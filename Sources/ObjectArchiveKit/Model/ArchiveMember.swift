//
//  ArchiveMember.swift
//  MachOKit
//
//  Created by p-x9 on 2026/03/06
//
//

import Foundation

public struct ArchiveMember: Sendable {
    public let header: ArchiveMemberHeader
    public let offset: Int
}
