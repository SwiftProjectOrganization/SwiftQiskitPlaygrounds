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
        return states.map { state in
            Figure(name: state.name, group: "bloch") {
                AnyView(BlochSphereView(label: state.label, bloch: BlochVector(state.ket)))
            }
        }
    }
}
