// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftUIPrototype",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "SwiftUIPrototype", targets: ["SwiftUIPrototype"])
    ],
    targets: [
        .executableTarget(
            name: "SwiftUIPrototype",
            path: ".",
            sources: [
                "CanvasViewModel.swift",
                "StickyNoteView.swift",
                "LassoSelectionView.swift",
                "CanvasPrototypeView.swift",
                "PrototypeTestApp.swift"
            ]
        )
    ]
)
