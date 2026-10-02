// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "truenas_native_plugins",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "truenas-native-plugins", targets: ["truenas_native_plugins"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
    ],
    targets: [
        .target(
            name: "truenas_native_plugins",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
            ],
            linkerSettings: [
                .linkedFramework("CloudKit"),
                .linkedFramework("Security"),
            ]
        ),
    ]
)
