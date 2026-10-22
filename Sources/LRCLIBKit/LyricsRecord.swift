//
//  LyricsRecord.swift
//  LRCLIBKit
//
//  Created by Ringo Wathelet on 2026/10/23.
//
import Foundation
import SwiftUI


/// For every endpoint that returns a lyrics record
public struct LyricsRecord: Codable, Equatable, Identifiable, Hashable, Sendable {
    public let id: Int64
    public let name: String?
    public let trackName: String?
    public let artistName: String?
    public let albumName: String?
    public let duration: Double?
    public let instrumental: Bool?
    public let hasWordSync: Bool?
    public let plainLyrics: String?
    public let syncedLyrics: String?
    public let lyricsfile: String?
}
