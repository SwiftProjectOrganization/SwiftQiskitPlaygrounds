//: [Previous](@previous)
/*:
 # Exporting a Bloch sphere

 - The state |+⟩ = (|0⟩ + |1⟩)/√2 lies on the +x axis of the Bloch sphere:
   (x, y, z) = (1, 0, 0), θ = π/2, φ = 0.
 - `BlochSphereView` draws it; `BlochVector(Ket.plus)` supplies the coordinates.
 - SwiftQiskit 0.9.1 adds `writePNG(to:)` (scale 2 by default, white background, light
   appearance) and `writePDF(to:)` (single-page vector PDF) for `SwiftQiskitViews` views.
 - Limit: calling them inside a playground fails with "Failed to load linked library cups of
   module SwiftUI" (Xcode 27.2), so this page only shows the view and lists the calls.
   `Tools/ExportBlochSphere` makes the same view and writes the two files. From the
   repository root, run `swift run --package-path Tools/ExportBlochSphere ExportBlochSphere [folder]`.
   The files go to `~/Documents/QiskitFigures` unless a folder is given; it is created if needed.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

let bloch = BlochVector(Ket.plus)
print("x \(bloch.x)  y \(bloch.y)  z \(bloch.z)  θ \(bloch.theta)  φ \(bloch.phi)")

let view = BlochSphereView(label: "|+⟩", bloch: bloch)

// What Tools/ExportBlochSphere runs (disabled here, see the note above):
// try view.writePNG(to: URL(fileURLWithPath: "plus.png"))   // scale: 2 by default
// try view.writePDF(to: URL(fileURLWithPath: "plus.pdf"))   // single-page vector PDF

PlaygroundPage.current.setLiveView(view.padding())

//: [Next](@next)
