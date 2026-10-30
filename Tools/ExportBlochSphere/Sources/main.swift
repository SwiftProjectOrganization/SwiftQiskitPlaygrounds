import Foundation
import SwiftUI
import SwiftQiskit
import SwiftQiskitViews

// Writes plus.png (scale 2) and plus.pdf for |+⟩ into the directory given as the first
// argument, or ~/Documents/QiskitFigures by default. The directory is created if needed.
let folder: URL = CommandLine.arguments.dropFirst().first.map {
    URL(fileURLWithPath: $0, isDirectory: true)
} ?? FileManager.default.homeDirectoryForCurrentUser
    .appending(path: "Documents/QiskitFigures", directoryHint: .isDirectory)

MainActor.assumeIsolated {
    let view = BlochSphereView(label: "|+⟩", bloch: BlochVector(Ket.plus))
    do {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try view.writePNG(to: folder.appending(path: "plus.png"))
        try view.writePDF(to: folder.appending(path: "plus.pdf"))
        print("Wrote plus.png and plus.pdf to \(folder.standardizedFileURL.path)")
    } catch {
        print("Export failed: \(error)")
        exit(1)
    }
}
