// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AulaKnob",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "AulaKnob", targets: ["AulaKnob"])
    ],
    targets: [
        .executableTarget(
            name: "AulaKnob",
            dependencies: [],
            path: "Sources/AulaKnob",
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("Carbon"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
