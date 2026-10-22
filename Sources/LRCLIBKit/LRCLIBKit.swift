//
//  LRCLIBKit.swift
//
//  Created by Ringo Wathelet on 2026/10/22.
//

import Foundation

/// A LRCLIB API client.
///
/// see the documentations at:  https://lrclib.net/docs
///
public struct LrcClient {
    private let baseURL: URL
    private let lrclibID: String?
    private let userAgent: String
    private let session: URLSession

    public init(
        baseURL: URL = URL(string: "https://lrclib.net/api/")!,
        lrclibID: String? = "uffDOEor4luWEl3ltIARG5BFdaw29uImqIKBTIHVBYY",
        userAgent: String = "LRCLIBKit v0.1.0 (https://github.com/workingDog/LRCLIBKit)",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.lrclibID = lrclibID
        self.userAgent = userAgent
        self.session = session
    }

     /// Attempt to find the best match of lyrics for the track. You must provide the track title and the artist name. Providing the album name and the track's duration in seconds is recommended and improves the matching precision.
     /// If no match is found, the API returns 404 Not Found. Missing tracks can be picked up by the background lyrics fetching service and may become available in a later request.
     /// Note: The provided duration is crucial. LRCLIB will attempt to provide the lyrics only when the duration matches the record in LRCLIB's database, or at least with a difference of ±2 seconds in duration.
    public func get(
        trackName: String,
        artistName: String,
        albumName: String? = nil,
        duration: UInt? = nil
    ) async throws -> LyricsRecord {
        let endpoint = "get"
        var queryItems = [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: artistName)
        ]
        if let albumName {
            queryItems.append(URLQueryItem(name: "album_name", value: albumName))
        }
        if let duration {
            queryItems.append(URLQueryItem(name: "duration", value: String(duration)))
        }
        
        return try await request(endpoint, queryItems: queryItems)
    }
    
    /// Get a lyrics record by the track's absolute ID. Track IDs are returned by other APIs, such as /api/get and /api/search
    public func get(id: Int64) async throws -> LyricsRecord {
        try await request("get/\(id)")
    }

    /// Search for lyrics records using keywords. This API returns an array of lyrics records that match the specified search condition(s).
    /// At least ONE of the two parameters, q OR track_name, must be present. If neither is provided, an empty array is returned.
    /// Note: This API currently returns a maximum of 20 results and does not support pagination. These limitations are subject to change in the future.
    public func search(
        query: String? = nil,
        trackName: String? = nil,
        artistName: String? = nil,
        albumName: String? = nil
    ) async throws -> [LyricsRecord] {

        guard query?.isEmpty == false || trackName?.isEmpty == false else {
            throw ServerError.searchBothNil
        }
        
        var queryItems: [URLQueryItem] = []
        
        if let query {
            queryItems.append(.init(name: "q", value: query))
        }
        
        if let trackName {
            queryItems.append(.init(name: "track_name", value: trackName))
        }
        
        if let artistName {
            queryItems.append(.init(name: "artist_name", value: artistName))
        }
        
        if let albumName {
            queryItems.append(.init(name: "album_name", value: albumName))
        }
        
        return try await request("/search", queryItems: queryItems)
    }
    
    /// Server request
    private func request<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem] = []) async throws -> T {
        
        let url = baseURL
            .appending(path: endpoint)
            .appending(queryItems: queryItems)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        if let lrclibID {
            request.setValue(lrclibID, forHTTPHeaderField: "Lrclib-App-Id")
        }
        
        // retry ---> todo
        
        let (data, response) = try await session.data(for: request)
        
        guard let response = response as? HTTPURLResponse else {
            throw ServerError.invalidResponse
        }
        
        guard (200..<300).contains(response.statusCode) else {
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
            if let error = try? JSONDecoder().decode(LyricsError.self, from: data) {
                throw ServerError.apiError(error, retryAfter: retryAfter)
            }
            throw ServerError.httpErrorCode(response.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
}

/// Every endpoint that returns lyrics records
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

/// server errors
public enum ServerError: Error, Equatable {
    case httpErrorCode(_ responseCode: Int)
    case searchBothNil
    case invalidResponse
    case apiError(LyricsError, retryAfter: String?)
}

/// the error returned
public struct LyricsError: Codable, Sendable, Equatable {
    public let statusCode: Int
    public let name: String
    public let message: String
}
