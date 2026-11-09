//
//  LyricsRecord.swift
//  LRCLIBKit
//
//  Created by Ringo Wathelet on 2026/10/23.
//
import Foundation


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
    
    public init(id: Int64, name: String?, trackName: String?, artistName: String?, albumName: String?, duration: Double?, instrumental: Bool?, hasWordSync: Bool?, plainLyrics: String?, syncedLyrics: String?, lyricsfile: String?) {
        self.id = id
        self.name = name
        self.trackName = trackName
        self.artistName = artistName
        self.albumName = albumName
        self.duration = duration
        self.instrumental = instrumental
        self.hasWordSync = hasWordSync
        self.plainLyrics = plainLyrics
        self.syncedLyrics = syncedLyrics
        self.lyricsfile = lyricsfile
    }
}

public struct LyricsFile: Codable {
    public let version: String
    public let metadata: Metadata
    public let lines: [LyricLine]
    public let plain: String
    
    public init(version: String, metadata: Metadata, lines: [LyricLine], plain: String) {
        self.version = version
        self.metadata = metadata
        self.lines = lines
        self.plain = plain
    }
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
    
    public init(title: String, artist: String, album: String, durationMs: Int, instrumental: Bool) {
        self.title = title
        self.artist = artist
        self.album = album
        self.durationMs = durationMs
        self.instrumental = instrumental
    }
}

public struct LyricLine: Codable, Identifiable,Sendable {
    public let id = UUID()
    
    public let text: String
    public let startMs: Int
    public let endMs: Int?
    public let words: [LyricWord]?
    
    enum CodingKeys: String, CodingKey {
        case text, words
        case startMs = "start_ms"
        case endMs = "end_ms"
    }
    
    public init(text: String, startMs: Int, endMs: Int?, words: [LyricWord]?) {
        self.text = text
        self.startMs = startMs
        self.endMs = endMs
        self.words = words
    }
}

public struct LyricWord: Codable, Identifiable, Sendable {
    public let id = UUID()
    
    public let text: String
    public let startMs: Int
    public let endMs: Int?
    
    enum CodingKeys: String, CodingKey {
        case text
        case startMs = "start_ms"
        case endMs = "end_ms"
    }
    
    public init(text: String, startMs: Int, endMs: Int?) {
        self.text = text
        self.startMs = startMs
        self.endMs = endMs
    }
}

///
/// basic LRC format
///

public struct LRCFile {
    public var metadata: LRCMetadata
    public var lines: [LRCLine]
    public var offsetMs: Int
    
    public init(metadata: LRCMetadata, lines: [LRCLine], offsetMs: Int) {
        self.metadata = metadata
        self.lines = lines
        self.offsetMs = offsetMs
    }
}

extension LRCFile {
    
    public init(syncedLyrics: String) {
        var metadata = LRCMetadata()
        var lines: [LRCLine] = []
        var offsetMs = 0
        var sequence = 0
        
        let timestampRegex = /\[(\d+):(\d{1,2})(?:[.,](\d{1,3}))?\]/
        let metadataRegex = /^\[(\w+):([^\]]*)\]$/
        
        for rawLine in syncedLyrics.components(separatedBy: .newlines) {
            var text = rawLine
            var timestamps: [Int] = []
            
            for match in rawLine.matches(of: timestampRegex).reversed() {
                guard let minutes = Int(match.1), let seconds = Int(match.2), seconds < 60 else { continue }
                let fractionString = String(match.3 ?? "")
                let milliseconds = Int(fractionString.padding(toLength: 3, withPad: "0", startingAt: 0)) ?? 0
                timestamps.append((minutes * 60 + seconds) * 1000 + milliseconds)
                text.replaceSubrange(match.range, with: "")
            }
            
            if timestamps.isEmpty {
                let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if let match = trimmed.wholeMatch(of: metadataRegex) {
                    let key = String(match.1).lowercased()
                    let value = String(match.2)
                    switch key {
                        case "ti": metadata.title = value
                        case "ar": metadata.artist = value
                        case "al": metadata.album = value
                        case "by": metadata.by = value
                        case "offset": offsetMs = Int(value) ?? 0
                        default: break
                    }
                }
                continue
            }
            let lyricText = text.trimmingCharacters(in: .whitespaces)
            for timestamp in timestamps.reversed() {
                lines.append(LRCLine(startMs: timestamp, text: lyricText, words: nil))
                sequence += 1
            }
        }
        self.metadata = metadata
        self.lines = lines.enumerated()
            .sorted { lhs, rhs in
                lhs.element.startMs == rhs.element.startMs
                ? lhs.offset < rhs.offset
                : lhs.element.startMs < rhs.element.startMs
            }
            .map(\.element)
        self.offsetMs = offsetMs
    }
    
}

public struct LRCMetadata {
    public var title: String?
    public var artist: String?
    public var album: String?
    public var by: String?
    
    public init(title: String? = nil, artist: String? = nil, album: String? = nil, by: String? = nil) {
        self.title = title
        self.artist = artist
        self.album = album
        self.by = by
    }
}

public struct LRCLine: Identifiable, Sendable {
    public let id = UUID()
    
    /// Timestamp in milliseconds from the start of the track.
    public var startMs: Int
    public var text: String
    public var words: [LRCWord]?
    
    public init(startMs: Int, text: String, words: [LRCWord]? = nil) {
        self.startMs = startMs
        self.text = text
        self.words = words
    }
}

public struct LRCWord: Identifiable, Sendable {
    public let id = UUID()
    
    /// Timestamp in milliseconds from the start of the track.
    public var startMs: Int
    public var text: String
    
    public init(startMs: Int, text: String) {
        self.startMs = startMs
        self.text = text
    }
}

