//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Single-qubit examples
// ------------------------------------------------------------

// Single qubit examples. See 02Bloch2d for more qubit examples.
let q0: Ket = .zero
let q1: Ket = .plusI

// ------------------------------------------------------------
// §2 — Multi-qubit creation
// ------------------------------------------------------------

// Multi qubit creation examples
let sv0: StateVector = Ket("000")
let sv1: StateVector = Ket("010")
let sv2: StateVector = .zero ⊗ .plusI ⊗ .zero ⊗ .zero

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
// §5 — Bra/Ket operations
// ------------------------------------------------------------

// Operations with Bra and Ket objects

let ket0 = Ket([Complex(6), Complex(8)])

// Notice the normalisation of ket0

let bra0 = ket0†
bra0 * ket0
ket0.amplitudes
ket0.probabilities
ket0†
ket0† * ket0
ket0 ⊗ ket0
(ket0†)†
ket0 * ket0†
ket0† * Matrix.identity(size: 2)

HadamardGate.matrix
Matrix.identity(size: 2) * HadamardGate.matrix
Matrix.identity(size: 2) ⊗ HadamardGate.matrix

let ket1 = Ket([Complex(0.8), Complex(0.4243, 0.4243)])
let bra1 = ket1†
bra1 * ket1
ket1.dimension.magnitude
ket1.amplitudes
ket1.probabilities
ket1†
ket1† * ket1
ket1 ⊗ ket1
bra1 ⊗ ket1
(ket1†)†
ket1 * ket1†
ket1† * Matrix.identity(size: 2)

// ------------------------------------------------------------
// §6 — Live view
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

// ------------------------------------------------------------
// §7 — Basis transformations (preview of 41BasisTransformations §1–4)
// ------------------------------------------------------------

// Given |ψ⟩ in the computational basis {|0⟩, |1⟩}, what are its coordinates in a
// different basis, e.g. {|+⟩, |−⟩}? Stack the new basis kets as the columns of T, so
// |ψ⟩ = T·c; since T is unitary, c = T⁻¹|ψ⟩ = T†|ψ⟩,
// the library's own `†` (Matrix.adjoint) already is T⁻¹ for a unitary T.

let psi: Ket = .zero
// want c₊, c₋ such that |ψ⟩ = c₊|+⟩ + c₋|−⟩

let T = Matrix((0..<2).map { row in [Ket.plus[row], Ket.minus[row]] })
let Tdag = T†

let c = Tdag.multiply(by: psi.amplitudes)
// [0.7071067811865475, 0.7071067811865475]

Ket.plus† * psi
// = c[0] — row j of T† times ψ is literally the inner product ⟨bⱼ|ψ⟩
Ket.minus† * psi
// = c[1]

c.map { $0.magnitudeSquared }
// [0.5, 0.5] — |0⟩ is certain in Z, an even split in ±

Tdag.multiply(by: Ket.plus.amplitudes)
// [1, 0] — |+⟩ is certain in its own basis

Tdag.multiply(by: Ket.plusI.amplitudes)
// an even split again — |+i⟩ is as undetermined in ± as |0⟩ is

// Same machinery on ket1 (§5 above), which isn't a Z eigenstate either:
let c1 = Tdag.multiply(by: ket1.amplitudes)
c1.map { $0.magnitudeSquared }
// vs. ket1's own Z-basis probabilities [0.75, 0.25] — a different basis, a different
// distribution

// A complex basis {|+i⟩, |−i⟩}: same column-mapping/T† recipe, no hand-built rows of bras.
let T2 = Matrix((0..<2).map { row in [Ket.plusI[row], Ket.minusI[row]] })
let Tdag2 = T2†

Tdag2.multiply(by: Ket.plusI.amplitudes)
// [1, 0] — |+i⟩ is certain once expressed in its own basis

// See 41BasisTransformations for why T† (not a plain transpose) is required here, and
// how to measure directly in a new basis.

//: [Next](@next)
