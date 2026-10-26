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

public struct LyricsFile: Codable {
    public let version: String
    public let metadata: Metadata
    public let lines: [LyricLine]
    public let plain: String
}

public struct Metadata: Codable {
    public let title: String
    public let artist: String
    public let album: String
    public let durationMs: Int
    public let instrumental: Bool

    enum CodingKeys: String, CodingKey {
        case title, artist, album, instrumental
        case durationMs = "duration_ms"
    }
}

public struct LyricLine: Codable {
    public let text: String
    public let startMs: Int
    public let endMs: Int?
    public let words: [LyricWord]?

    enum CodingKeys: String, CodingKey {
        case text, words
        case startMs = "start_ms"
        case endMs = "end_ms"
    }
}

public struct LyricWord: Codable {
    public let text: String
    public let startMs: Int
    public let endMs: Int?  // <---

    enum CodingKeys: String, CodingKey {
        case text
        case startMs = "start_ms"
        case endMs = "end_ms"
    }
}

public struct LRCFile {
    public var metadata: LRCMetadata
    public var lines: [LRCLine]
    public var offsetMs: Int
}

public struct LRCMetadata {
    public var title: String?
    public var artist: String?
    public var album: String?
    public var by: String?
}

public struct LRCLine {
    /// Timestamp in milliseconds from the start of the track.
    public var startMs: Int
    public var text: String
    public var words: [LRCWord]?
}

public struct LRCWord {
    /// Timestamp in milliseconds from the start of the track.
    public var startMs: Int
    public var text: String
}

extension LRCFile {

    public init(syncedLyrics: String) {
        var metadata = LRCMetadata()
        var lines: [LRCLine] = []
        var offsetMs = 0
        let timestampRegex = /\[(\d{2,}):(\d{2})(?:\.(\d{1,3}))?\]/
        
        for rawLine in syncedLyrics.components(separatedBy: .newlines) {
            var text = rawLine
            var timestamps: [Int] = []
            
            for match in rawLine.matches(of: timestampRegex).reversed() {
                let minutes = Int(match.1) ?? 0
                let seconds = Int(match.2) ?? 0
                let fraction = Int(String(match.3 ?? "").padding(toLength: 3, withPad: "0", startingAt: 0)) ?? 0
                timestamps.append((minutes * 60 + seconds) * 1000 + fraction)
                text.replaceSubrange(match.range, with: "")
            }
            
            if timestamps.isEmpty {
                if rawLine.hasPrefix("[ti:") {
                    metadata.title = String(rawLine.dropFirst(4).dropLast())
                } else if rawLine.hasPrefix("[ar:") {
                    metadata.artist = String(rawLine.dropFirst(4).dropLast())
                } else if rawLine.hasPrefix("[al:") {
                    metadata.album = String(rawLine.dropFirst(4).dropLast())
                } else if rawLine.hasPrefix("[by:") {
                    metadata.by = String(rawLine.dropFirst(4).dropLast())
                } else if rawLine.hasPrefix("[offset:") {
                    offsetMs = Int(rawLine.dropFirst(8).dropLast()) ?? 0
                }
                continue
            }
            let lyricText = text.trimmingCharacters(in: .whitespaces)
            for timestamp in timestamps {
                lines.append(LRCLine(startMs: timestamp, text: lyricText, words: nil))
            }
        }
        self.metadata = metadata
        self.lines = lines.sorted { $0.startMs < $1.startMs }
        self.offsetMs = offsetMs
    }
}


/*
 
 I have this code: "
 public struct LyricsFile: Codable {
     public let version: String
     public let metadata: Metadata
     public let lines: [LyricLine]
     public let plain: String
 }

 public struct Metadata: Codable {
     public let title: String
     public let artist: String
     public let album: String
     public let durationMs: Int
     public let instrumental: Bool

     enum CodingKeys: String, CodingKey {
         case title, artist, album, instrumental
         case durationMs = "duration_ms"
     }
 }

 public struct LyricLine: Codable {
     public let text: String
     public let startMs: Int
     public let endMs: Int?
     public let words: [LyricWord]?

     enum CodingKeys: String, CodingKey {
         case text, words
         case startMs = "start_ms"
         case endMs = "end_ms"
     }
 }

 public struct LyricWord: Codable {
     public let text: String
     public let startMs: Int
     public let endMs: Int?  // <---

     enum CodingKeys: String, CodingKey {
         case text
         case startMs = "start_ms"
         case endMs = "end_ms"
     }
 }
" that I use to retrieve the lyrics of a song. I want to display the lyrics and highlight the corresponding word as a function of time. How to do this using modern SwiftUI?
 
 
 
 
 
 
 
 */
