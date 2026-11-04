// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Syntax",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "Syntax", targets: ["Syntax"]),
        .library(name: "SyntaxStyling", targets: ["SyntaxStyling"]),
        .library(name: "SyntaxLSP", targets: ["SyntaxLSP"]),
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
        .target(
            name: "SyntaxStyling",
            dependencies: ["Syntax"]
        ),
        .target(
            name: "SyntaxLSP",
            dependencies: [
                "Syntax",
                .product(name: "Position", package: "Position")
            ]
        ),
        .executableTarget(
            name: "SyntaxTests",
            dependencies: [
                "Syntax",
                "SyntaxStyling",
                "SyntaxLSP",
                .product(name: "Position", package: "Position"),
                .product(name: "Testing", package: "Testing")
            ],
            path: "Testing/SyntaxTests"
        )
    ]
)

for target in package.targets {
    switch target.type {
    case .regular, .executable, .test, .macro:
        var settings = target.swiftSettings ?? []

        settings.append(
            .treatAllWarnings(as: .error)
        )

        settings.append(
            .unsafeFlags(
                [
                    "-continue-building-after-errors"
                ]
            )
        )

        target.swiftSettings = settings

    case .plugin, .system, .binary:
        break

    @unknown default:
        break
    }
}
