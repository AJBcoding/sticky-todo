// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppKitPrototype",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AppKitPrototype", targets: ["AppKitPrototype"])
    ],
    targets: [
        .executableTarget(
            name: "AppKitPrototype",
            path: ".",
            sources: [
                "StickyNoteView.swift",
                "LassoSelectionOverlay.swift",
                "CanvasView.swift",
                "CanvasController.swift",
                "PrototypeWindow.swift"
            ]
        )
    ]
)
