import SwiftUI
import SwiftQiskit
import SwiftQiskitViews

extension Figures {
    /// The six canonical single-qubit states on the Bloch sphere.
    @MainActor public static var bloch: [Figure] {
        let states: [(name: String, label: String, ket: Ket)] = [
            ("bloch-zero", "|0⟩", Ket.zero),
            ("bloch-one", "|1⟩", Ket.one),
            ("bloch-plus", "|+⟩", Ket.plus),
            ("bloch-minus", "|−⟩", Ket.minus),
            ("bloch-plus-i", "|+i⟩", Ket.plusI),
            ("bloch-minus-i", "|−i⟩", Ket.minusI)
        ]
        let basis = states.map { state in
            Figure(name: state.name, group: "bloch") {
                AnyView(BlochSphereView(label: state.label, bloch: BlochVector(state.ket)))
            }
        }
        return basis + [general]
    }

    /// A general state at polar angle θ = 60° and azimuth φ = 45°.
    @MainActor private static var general: Figure {
        let theta = deg2rad(60.0)
        let phi = deg2rad(45.0)
        let vector = BlochVector(
            x: sin(theta) * cos(phi),
            y: sin(theta) * sin(phi),
            z: cos(theta)
        )
        return Figure(name: "bloch-theta60-phi45", group: "bloch") {
            AnyView(BlochSphereView(label: "θ = 60°, φ = 45°", bloch: vector))
        }
    }
}
