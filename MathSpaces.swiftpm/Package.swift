// swift-playgrounds-dev-contentType: com.apple.playgrounds.appproject
// swift-tools-version: 5.9

import AppleProductTypes
import PackageDescription

let package = Package(
    name: "MathSpaces",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "MathSpaces",
            targets: ["MathSpaces"],
            bundleIdentifier: "com.mathspaces.app",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown
            ]
        )
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
