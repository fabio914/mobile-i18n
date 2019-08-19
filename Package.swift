// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "i18nGen",
    products: [
        .executable(name: "i18nGen", targets: ["i18nGen"])
    ],
    dependencies: [
        .package(url: "https://github.com/behrang/YamlSwift.git", from: "3.4.4"),
    ],
    targets: [
        .target(
            name: "i18nGen",
            dependencies: ["Yaml", "i18nGenCore"]
        ),
        .target(
            name: "i18nGenCore",
            dependencies: ["Yaml"]
        ),
        .testTarget(
            name: "i18nGenTests",
            dependencies: ["Yaml", "i18nGenCore"]
        )
    ]
)
