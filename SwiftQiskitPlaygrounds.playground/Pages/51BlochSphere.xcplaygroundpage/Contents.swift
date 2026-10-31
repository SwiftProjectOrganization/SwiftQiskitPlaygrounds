//: [Previous](@previous)
/*:
 # Exporting a Bloch sphere

 - The state |+⟩ = (|0⟩ + |1⟩)/√2 lies on the +x axis of the Bloch sphere:
   (x, y, z) = (1, 0, 0), θ = π/2, φ = 0.
 - `BlochSphereView` draws it; `BlochVector(Ket.plus)` supplies the coordinates.
 - SwiftQiskit 0.9.1 adds `writePNG(to:)` (scale 2 by default, white background, light
   appearance) and `writePDF(to:)` (single-page vector PDF) for `SwiftQiskitViews` views.
 - Limit: calling them inside a playground fails with "Failed to load linked library cups of
   module SwiftUI" (Xcode 27.2), so this page only shows the view.
 - The `QiskitFigures` package (`Tools/QiskitFigures`) defines the figures once. This page
   shows `bloch-plus` from it, and `ExportFigures` writes the same figure to disk. From the
   repository root, run `swift run --package-path Tools/QiskitFigures ExportFigures bloch-plus`,
   or `--list` to see every figure. The files go to `~/Documents/QiskitFigures` unless
   `--out <folder>` is given; the folder is created if needed.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews
import QiskitFigures

let bloch = BlochVector(Ket.plus)
print("x \(bloch.x)  y \(bloch.y)  z \(bloch.z)  θ \(bloch.theta)  φ \(bloch.phi)")

// Playground top-level code runs on the main thread, but is not marked main-actor isolated.
MainActor.assumeIsolated {
    guard let figure = Figures.named("bloch-plus") else { fatalError("figure bloch-plus is missing") }
    PlaygroundPage.current.setLiveView(figure.view.padding())
}

//: [Next](@next)
