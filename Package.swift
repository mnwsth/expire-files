// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "ExpireFiles",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ExpireFiles",
            targets: ["ExpireFiles"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ExpireFiles",
            dependencies: [],
            path: "Sources"
        )
    ]
)
