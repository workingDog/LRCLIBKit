//
//  LrcClient.swift
//  LRCLIBKit
//
//  Created by Ringo Wathelet on 2026/10/23.
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
    
    private let maxAttempts = 3
    private let defaultRetryDelay: TimeInterval = 1
    
    public init(
        baseURL: URL = URL(string: "https://lrclib.net/api/")!,
        lrclibID: String? = nil,
        userAgent: String = "LRCLIBKit v1.0.0 (https://github.com/workingDog/LRCLIBKit)",
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
    public func getLyrics(
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
    public func getLyrics(id: Int64) async throws -> LyricsRecord {
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
        
        for attempt in 1...maxAttempts {
            let data: Data
            let response: URLResponse
            
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                guard attempt < maxAttempts, shouldRetry(error) else {
                    throw error
                }
                try await Task.sleep(for: .seconds(defaultRetryDelay * pow(2, Double(attempt - 1))))
                continue
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServerError.invalidResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                let retryable = [429, 503].contains(httpResponse.statusCode)
                guard retryable, attempt < maxAttempts else {
                    let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    if let error = try? JSONDecoder().decode(LyricsError.self, from: data) {
                        throw ServerError.apiError(error, retryAfter: retryAfter)
                    }
                    throw ServerError.httpErrorCode(httpResponse.statusCode)
                }
                let delay = retryDelay(from: httpResponse, attempt: attempt)
                try await Task.sleep(for: .seconds(delay))
                continue
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        }
        throw ServerError.invalidResponse
    }
    
    private func retryDelay(from response: HTTPURLResponse?, attempt: Int) -> TimeInterval {
        if let value = response?.value(forHTTPHeaderField: "Retry-After") {
            if let seconds = TimeInterval(value), seconds >= 0 {
                return seconds
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
            if let date = formatter.date(from: value) {
                return max(0, date.timeIntervalSinceNow)
            }
        }
        return defaultRetryDelay * pow(2, Double(attempt - 1))
    }
    
    private func shouldRetry(_ error: Error) -> Bool {
        guard !Task.isCancelled, let error = error as? URLError else { return false }
        return [
            .timedOut,
            .networkConnectionLost,
            .notConnectedToInternet,
            .cannotConnectToHost,
            .cannotFindHost,
            .dnsLookupFailed
        ].contains(error.code)
    }

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
