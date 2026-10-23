//: [Previous](@previous)
/*:
 # Qubits: amplitudes and probabilities

 Follows Chapter 3 of the SwiftQiskitApp introduction (`Docs/Introduction/03-Qubits.md`).

 A qubit is a `StateVector` (`Ket` is a typealias) holding two complex amplitudes α and β, one
 per outcome. The type enforces `|α|² + |β|² = 1`: `init` normalizes on construction and every
 gate renormalizes afterward.

 A `StateVector` supports two readings:
 - `.amplitudes` is the complete description of the state;
 - `.probabilities` is what a measurement can deliver — the Born rule `|amplitude|²`, which
   throws phase away. `|+⟩` and `|+i⟩` are different states with identical probabilities.

 The two circuits below make the point: in `H;P;P` only the phase moves, while in `H;Z;H` the
 sign flip from `Z` is invisible until the second `H` turns it into a definite `|1⟩`
 (explained in 08Interference). Each stage is shown live on a Bloch sphere.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Single-qubit examples
// ------------------------------------------------------------

// Single qubit examples. See 06BlochSpheres for more qubit examples.
let q0: Ket = .zero
print("print(q0):\n\(q0)\n")

let q1: Ket = .plusI
print("print(q1):\n\(q1)\n")

// ------------------------------------------------------------
// §2 — Multi-qubit creation
// ------------------------------------------------------------

// Multi qubit creation examples
let sv0: StateVector = Ket("000")
print("print(sv0):\n\(sv0)\n")

let sv1: StateVector = .zero ⊗ .zero ⊗ .zero
print("print(sv1):\n\(sv1)\n")

let sv2: StateVector = Ket("010")
print("print(sv2):\n\(sv2)\n")

let sv3: StateVector = .zero ⊗ .plusI ⊗ .zero
print("print(sv3):\n\(sv3)\n")

let sv4: StateVector = .zero ⊗ .plusI ⊗ .zero ⊗ .zero
print("print(sv4):\n\(sv4)\n")

// ------------------------------------------------------------
// §3 — circuit1 stages
// ------------------------------------------------------------

// Single qubit circuit examples
// Quantum circuit are needed to apply quantum gates

// The circuit1 and circuit2 stages below
// are shown live on Bloch spheres

var stages1: [(name: String, bloch: BlochVector)] = []
let circuit1 = QuantumCircuit(qubits: 1)

stages1.append(("|0⟩", BlochVector(circuit1.run())))
circuit1.h(0)
stages1.append(("H → |+⟩", BlochVector(circuit1.run())))
circuit1.p(1.571, 0)
stages1.append(("P(π/2) → |+i⟩", BlochVector(circuit1.run())))
circuit1.p(3.142, 0)
stages1.append(("P(π) → |−i⟩", BlochVector(circuit1.run())))
circuit1.run().probabilities


// ------------------------------------------------------------
// §4 — circuit2 stages
// ------------------------------------------------------------

var stages2: [(name: String, bloch: BlochVector)] = []
let circuit2 = QuantumCircuit(qubits: 1)
circuit2.run().probabilities
stages2.append(("|0⟩", BlochVector(circuit2.run())))
circuit2.h(0)
circuit2.run().probabilities
stages2.append(("H → |+⟩", BlochVector(circuit2.run())))
circuit2.z(0)
circuit2.run().probabilities
stages2.append(("Z → |−⟩", BlochVector(circuit2.run())))
circuit2.h(0)
circuit2.run().probabilities
stages2.append(("H → |1⟩", BlochVector(circuit2.run())))

// ------------------------------------------------------------
// §5 — Live view
// ------------------------------------------------------------

// Live view: the circuit1 and circuit2 stages on Bloch spheres.
// Stateless view (no @State) — required for page code, see PLAYGROUNDSUPPORT.md.

struct CircuitStagesView: View {
    let sections: [(title: String, stages: [(name: String, bloch: BlochVector)])]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(sections, id: \.title) { section in
                Text(section.title)
                    .font(.title3.bold())
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(260)), count: 2), spacing: 16) {
                    ForEach(section.stages, id: \.name) { stage in
                        BlochSphereView(label: stage.name, bloch: stage.bloch)
                    }
                }
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    CircuitStagesView(sections: [
        ("circuit1", stages1),
        ("circuit2", stages2)
    ])
    .frame(width: 560, height: 1340)
)

//: [Next](@next)
