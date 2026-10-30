// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QiskitFigures",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "QiskitFigures", targets: ["QiskitFigures"]),
        .executable(name: "ExportFigures", targets: ["ExportFigures"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftProjectOrganization/SwiftQiskit.git", from: "0.9.1")
    ],
    targets: [
        .target(
            name: "QiskitFigures",
            dependencies: [
                .product(name: "SwiftQiskit", package: "SwiftQiskit"),
                .product(name: "SwiftQiskitViews", package: "SwiftQiskit")
            ],
            path: "Sources/QiskitFigures"
        ),
        .executableTarget(
            name: "ExportFigures",
            dependencies: [
                "QiskitFigures",
                .product(name: "SwiftQiskitViews", package: "SwiftQiskit")
            ],
            path: "Sources/ExportFigures"
        )
    ]
)
