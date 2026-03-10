// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "MathSpaces",
    platforms: [
        .iOS("16.0")
    ],
    targets: [
        .executableTarget(
            name: "MathSpaces",
            path: "Sources",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
