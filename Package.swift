// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Syntax",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "Syntax", targets: ["Syntax"]),
        .executable(name: "t_syntax", targets: ["SyntaxTests"])
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Position.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Testing.git", branch: "master")
    ],
    targets: [
        .target(
            name: "Syntax",
            dependencies: [
                .product(name: "Position", package: "Position"),
                .product(name: "Primitives", package: "Primitives")
            ]
        ),
        .executableTarget(
            name: "SyntaxTests",
            dependencies: [
                "Syntax",
                .product(name: "Position", package: "Position"),
                .product(name: "Testing", package: "Testing")
            ],
            path: "Testing/SyntaxTests"
        )
    ]
)
