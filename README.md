#  LRCLIBKit

A Swift client for the lyrics library [LRCLIB](https://lrclib.net/), **a completely free service for finding and contributing synchronized lyrics, with an easy-to-use and machine-friendly APIs.**

## Example


```swift
import LRCLIBKit

        do {
            let client = LrcClient()
            let lyrics = try await client.get(trackName: "Venus", artistName: "Bananarama")
            print(lyrics.plainLyrics ?? "No plain lyrics")
        } catch ServerError.apiError(let error,  _) {
            switch error.statusCode {
                case 404: print("Lyrics not found")
                case 429: print("Rate limit exceeded")
                case 503: print("LRCLIB is temporarily overloaded")
                default: print("\(error.name): \(error.message)")
            }
        } catch ServerError.httpErrorCode(let statusCode) {
            print("HTTP error: \(statusCode)")
        } catch {
            print("Request failed: \(error.localizedDescription)")
        }
```

### Installation

Include the files in the **./Sources/LRCLIBKit** folder into your project or preferably use **Swift Package Manager**.

#### Swift Package Manager (SPM)

Create a Package.swift file for your project and add a dependency to:

```swift
dependencies: [
  .package(url: "https://github.com/workingDog/LRCLIBKit.git", branch: "main")
]
```

#### Using Xcode

    Select your project > Swift Packages > Add Package Dependency...
    https://github.com/workingDog/LRCLIBKit.git

Then in your code:

```swift
import LRCLIBKit
```
    
### References

-    [LRCLIB](https://lrclib.net/)



