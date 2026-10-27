#  LRCLIBKit

A very small Swift client for the lyrics library [LRCLIB](https://lrclib.net/), **"a completely free service for finding and contributing synchronized lyrics, with an easy-to-use and machine-friendly APIs."**

Only caters for the **GET** API, not the experimental **POST** API.


## Example

```swift
import SwiftUI
import LRCLIBKit

struct ContentView: View {
    @State private var lyrics: LyricsRecord?
    let client = LrcClient()
    
    var body: some View {
        ScrollView {
            Text(lyrics?.plainLyrics ?? "No lyrics")
        }
        .padding()
        .task {
            do {
                lyrics = try await client.getLyrics(trackName: "Venus", artistName: "Bananarama")
                print(lyrics?.plainLyrics ?? "No lyrics")
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
        }
    }
}
```

To obtain the LRC format data of the lyrics use:


```swift
        if let syncedLyricsString = lyrics?.syncedLyrics {
            let lrcFile = LRCFile(syncedLyrics: syncedLyricsString)
        }
```


To obtain the YAML LyricsFile format data use:


```swift
         if let lyricsfileString = lyrics?.lyricsfile {
             do {
                 let lyricsfile: LyricsFile? = try decoder.decode(LyricsFile.self, from: lyricsfileString)
             } catch  {
                 print(error)
             }
         }
```

where **decoder** is a YAML decoder, such as [YAMLDecoder](https://github.com/jpsim/Yams). 


### Installation

Include the files in the **./Sources/LRCLIBKit** folder into your project or preferably use **Swift Package Manager**.

#### Swift Package Manager (SPM)

Create a Package.swift file for your project and add a dependency to:

```swift
dependencies: [
    .package(url: "https://github.com/workingDog/LRCLIBKit.git", from: "1.0.1")
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

