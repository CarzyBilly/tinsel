// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Tinsel",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Tinsel", targets: ["Tinsel"])
    ],
    targets: [
        .executableTarget(name: "Tinsel", path: "Sources/Tinsel")
    ]
)
