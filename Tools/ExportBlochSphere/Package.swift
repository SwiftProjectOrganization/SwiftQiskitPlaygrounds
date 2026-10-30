// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExportBlochSphere",
    platforms: [.macOS("27.0")],
    dependencies: [
        .package(url: "https://github.com/SwiftProjectOrganization/SwiftQiskit", from: "0.9.1")
    ],
    targets: [
        .executableTarget(
            name: "ExportBlochSphere",
            dependencies: [
                .product(name: "SwiftQiskit", package: "SwiftQiskit"),
                .product(name: "SwiftQiskitViews", package: "SwiftQiskit")
            ],
            path: "Sources"
        )
    ]
)
