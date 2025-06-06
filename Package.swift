// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MastermindGame",
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.18.0")
    ],
    targets: [
        .executableTarget(
            name: "MastermindGame",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        )
    ]
)