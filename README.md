# MathSpaces

A Swift Playgrounds app for iPad that provides a math learning experience delivered via a built-in web view.

## Opening in Swift Playgrounds (iPad)

**Requires iPadOS 16 or later with Swift Playgrounds 4.0 or later.**

1. Clone or download this repository to your iPad using a Git client such as [Working Copy](https://workingcopyapp.com/) or transfer it via AirDrop / iCloud Drive.
2. In the **Files** app, navigate to the repository folder and tap **`MathSpaces.swiftpm`** — this opens the project directly in Swift Playgrounds.
3. Run the app from within Swift Playgrounds.

> **Important:** Open the `MathSpaces.swiftpm` package, **not** the root repository folder. Swift Playgrounds requires the `.swiftpm` bundle with its `Package.swift` manifest to identify a valid executable target.

## Project Structure

```
MathSpaces/  (repository root)
├── README.md
├── .gitignore
└── MathSpaces.swiftpm/          ← Open this in Swift Playgrounds
    ├── Package.swift            ← Swift Package manifest (defines the executable target)
    └── Sources/
        ├── App.swift            ← @main entry point
        ├── ContentView.swift    ← WKWebView wrapper that loads index.html
        └── Resources/           ← Web app files bundled as resources
            ├── index.html
            ├── app.js
            ├── styles.css
            ├── coordinates.html
            ├── license-manager.html
            ├── manifest.json
            ├── sw.js
            └── icons/
                ├── icon-192.png
                ├── icon-512.png
                └── icon.svg
```