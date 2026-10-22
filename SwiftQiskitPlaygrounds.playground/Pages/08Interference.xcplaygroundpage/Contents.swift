//: [Previous](@previous)
/*:
 # Phase, interference, and why Z hides

 A phase flip is invisible in probabilities, yet completely real. A second `H` turns that
 hidden phase into an observable bit flip through **interference**: amplitudes *add* before
 they are squared into probabilities.

 - A **global** phase (on every amplitude) is nothing: no measurement or gate recovers it.
 - A **relative** phase (on one amplitude of several) is everything interference can use.

 Follows Chapter 8 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Z alone on |0⟩: nothing observable
// ------------------------------------------------------------
// With one non-zero amplitude, any sign is a global phase.

let qcZ = QuantumCircuit(qubits: 1)
qcZ.z(0)
print("Z alone:", qcZ.run().amplitudes, qcZ.run().probabilities)
// [1, 0] [1, 0] — same as an empty circuit

// Global phase vanishes even from the Bloch sphere: H;Z;H;Z;H lands on −|−⟩.
let qcMinus = QuantumCircuit(qubits: 1)
qcMinus.h(0); qcMinus.z(0)
let qcGlobal = QuantumCircuit(qubits: 1)
qcGlobal.h(0); qcGlobal.z(0); qcGlobal.h(0); qcGlobal.z(0); qcGlobal.h(0)
print("|−⟩ :", qcMinus.run().amplitudes, BlochVector(qcMinus.run()))
print("−|−⟩:", qcGlobal.run().amplitudes, BlochVector(qcGlobal.run()))
// amplitudes differ by an overall −1, Bloch vectors are identical: x = −1

// ------------------------------------------------------------
// §2 — Z after H: the state changes, the probabilities don't
// ------------------------------------------------------------

let qcH = QuantumCircuit(qubits: 1)
qcH.h(0)
print("H  :", qcH.run().probabilities)
print("H;Z:", qcMinus.run().amplitudes, qcMinus.run().probabilities)
// [0.707, −0.707] [0.5, 0.5] — |+⟩ and |−⟩ are orthogonal, yet the same statistics

// ------------------------------------------------------------
// §3 — The second H: interference makes the phase visible
// ------------------------------------------------------------
// H sends (a, b) to ((a+b)/√2, (a−b)/√2). For (1/√2, −1/√2) the |0⟩ contributions
// cancel and the |1⟩ contributions reinforce.

let qcHZH = QuantumCircuit(qubits: 1)
qcHZH.h(0); qcHZH.z(0); qcHZH.h(0)
print("H;Z;H:", qcHZH.run().probabilities)
// ≈ [0, 1] — a deterministic bit flip from an unmeasurable phase

// ------------------------------------------------------------
// §4 — The fringe: any phase, not just π
// ------------------------------------------------------------
// H; P(φ); H gives p₀ = cos²(φ/2).

for k in 0...8 {
    let phi = Double(k) * .pi / 4
    let c = QuantumCircuit(qubits: 1)
    c.h(0); c.p(phi, 0); c.h(0)
    let p0 = c.run().probabilities[0]
    print(String(format: "phi %.4f  p0 %.4f  cos²(phi/2) %.4f", phi, p0, pow(cos(phi / 2), 2)))
}

// S and T are two more points on the same curve.
let qcHSH = QuantumCircuit(qubits: 1)
qcHSH.h(0); qcHSH.s(0); qcHSH.h(0)
let qcHTH = QuantumCircuit(qubits: 1)
qcHTH.h(0); qcHTH.t(0); qcHTH.h(0)
print("H;S;H:", qcHSH.run().probabilities)   // ≈ [0.5, 0.5]
print("H;T;H:", qcHTH.run().probabilities)   // ≈ [0.854, 0.146]

// Global phase drops out: RZ(φ) = e^{−iφ/2}·P(φ), so the fringes agree.
var maxPRZ = 0.0
for k in 0...8 {
    let phi = Double(k) * .pi / 4
    let a = QuantumCircuit(qubits: 1); a.h(0); a.p(phi, 0); a.h(0)
    let b = QuantumCircuit(qubits: 1); b.h(0); b.rz(phi, 0); b.h(0)
    for (x, y) in zip(a.run().probabilities, b.run().probabilities) {
        maxPRZ = max(maxPRZ, abs(x - y))
    }
}
print("max |P − RZ| over the fringe:", maxPRZ)
// ~1e-16

// ------------------------------------------------------------
// §5 — Reading interference off the sphere
// ------------------------------------------------------------
// H swaps the x and z coordinates (and flips y). Relative phase lives on the equator,
// probability on the z axis, and P(0) = (1 + x)/2 with x measured just before the final H.

var maxIdentity = 0.0
for k in 0...8 {
    let phi = Double(k) * .pi / 4
    let before = QuantumCircuit(qubits: 1)
    before.h(0); before.p(phi, 0)
    let after = QuantumCircuit(qubits: 1)
    after.h(0); after.p(phi, 0); after.h(0)
    let x = BlochVector(before.run()).x
    maxIdentity = max(maxIdentity, abs((1 + x) / 2 - after.run().probabilities[0]))
}
print("max |(1 + x)/2 − P(0)|:", maxIdentity)
// ~1e-16

// ------------------------------------------------------------
// §6 — Getting the phase back: measure in the X basis
// ------------------------------------------------------------
// |+⟩ and |−⟩ look alike in the Z basis at any shot count. One H before measuring
// separates them completely.

let plusZ = QuantumCircuit(qubits: 1)
plusZ.h(0)
let plusX = QuantumCircuit(qubits: 1)
plusX.h(0); plusX.h(0)
let minusX = QuantumCircuit(qubits: 1)
minusX.h(0); minusX.z(0); minusX.h(0)

print("|+⟩ Z-basis:", plusZ.measure(shots: 1000).counts)     // roughly 500 / 500
print("|−⟩ Z-basis:", qcMinus.measure(shots: 1000).counts)   // roughly 500 / 500
print("|+⟩ X-basis:", plusX.measure(shots: 1000).counts)     // ["0": 1000]
print("|−⟩ X-basis:", minusX.measure(shots: 1000).counts)    // ["1": 1000]

// ------------------------------------------------------------
// §7 — Interference as the engine of algorithms
// ------------------------------------------------------------
// CZ phase-marks |11⟩ in the uniform superposition — invisible on its own. (The app has
// no CZ tile; it builds it as H on the target, CX, H on the target.)

let oracleOnly = QuantumCircuit(qubits: 2)
oracleOnly.h(0); oracleOnly.h(1)
oracleOnly.cz(0, 1)
print("oracle only:", oracleOnly.run().probabilities)
// ≈ [0.25, 0.25, 0.25, 0.25]

// Add a diffuser (H, Z on both qubits, CZ, H): all amplitude piles onto the marked branch.
let grover = QuantumCircuit(qubits: 2)
grover.h(0); grover.h(1)
grover.cz(0, 1)
grover.h(0); grover.h(1)
grover.z(0); grover.z(1)
grover.cz(0, 1)
grover.h(0); grover.h(1)
print("oracle + diffuser:", grover.run().probabilities)
// ≈ [0, 0, 0, 1] — a rehearsal for Deutsch, Deutsch–Jozsa and Grover

// ------------------------------------------------------------
// §8 — Live view
// ------------------------------------------------------------
// Top: the H;Z;H trajectory. Bottom: the state just before the final H for several φ —
// the azimuth around the equator that the final H turns into a latitude.
// Stateless view (no @State) — required for page code.

var trajectory: [(name: String, bloch: BlochVector)] = []
let steps = QuantumCircuit(qubits: 1)
trajectory.append(("|0⟩", BlochVector(steps.run())))
steps.h(0)
trajectory.append(("H → |+⟩", BlochVector(steps.run())))
steps.z(0)
trajectory.append(("Z → |−⟩", BlochVector(steps.run())))
steps.h(0)
trajectory.append(("H → |1⟩", BlochVector(steps.run())))

var equator: [(name: String, bloch: BlochVector)] = []
for (label, phi) in [("0", 0.0), ("π/4", Double.pi / 4), ("π/2", Double.pi / 2), ("π", Double.pi)] {
    let c = QuantumCircuit(qubits: 1)
    c.h(0); c.p(phi, 0)
    equator.append(("H;P(\(label))", BlochVector(c.run())))
}

struct InterferenceView: View {
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
    InterferenceView(sections: [
        ("H;Z;H trajectory", trajectory),
        ("Before the final H", equator)
    ])
    .frame(width: 560, height: 1340)
)

//: [Next](@next)
