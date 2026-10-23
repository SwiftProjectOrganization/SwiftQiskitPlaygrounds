//: [Previous](@previous)
/*:
 # Teleportation and Superdense Coding

 Teleportation moves an unknown qubit state |ψ⟩ across a shared Bell pair, using two
 classical bits. Superdense coding runs the same resource the other way: one qubit carries
 two classical bits.

 - q0 holds the payload |ψ⟩, q1 is Alice's half of the Bell pair, q2 is Bob's half.
 - Alice's Bell-basis rotation is `cx(0,1); h(0)`; Bob then needs `X^b Z^a`.
 - Each branch `ab` has probability ¼, whatever ψ is: nothing travels faster than light.
 - SwiftQiskit has no mid-circuit measurement, so the corrections are applied as
   **controlled** gates (`cx(1,2)` and CZ(0,2) = `h; cx; h`) before any measurement.
 - Afterwards the register factors as `|+⟩ ⊗ |+⟩ ⊗ |ψ⟩`: the state moved, it was not cloned.
 - Superdense coding encodes I / X / Z / ZX on one half of a Bell pair and decodes with certainty.

 Limit: both protocols run every branch in superposition. To look at one branch on its own,
 project with `(Ket * Bra) ⊗ I` as in §3.

 Follows Chapter 18 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func fmt(_ value: Complex) -> String {
    let sign = value.imag < 0 ? "-" : "+"
    return String(format: "%.4f %@ %.4fi", value.real, sign, abs(value.imag))
}

func bits(_ value: Int, width: Int) -> String {
    let s = String(value, radix: 2)
    return String(repeating: "0", count: max(0, width - s.count)) + s
}

func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { "|\(bits($0, width: qubits))⟩: \(fmt(state[$0]))" }
        .joined(separator: "   ")
}

func card(_ bloch: BlochVector) -> String {
    String(format: "x %+.4f  y %+.4f  z %+.4f  |r| %.4f", bloch.x, bloch.y, bloch.z, bloch.magnitude)
}

// ------------------------------------------------------------
// §1 — The protocol, stage by stage
// ------------------------------------------------------------

let theta = Double.pi / 3
let phi = Double.pi / 4
let psiCircuit = QuantumCircuit(qubits: 1)
psiCircuit.ry(theta, 0)
psiCircuit.rz(phi, 0)
let psi = psiCircuit.run()
print("psi:", pretty(psi, qubits: 1))
print("P(0), P(1):", psi.probabilities.map { String(format: "%.4f", $0) })
print("Bloch point:", card(BlochVector(psi, qubit: 0)))
// 0.6124, 0.6124, 0.5000 — rz adds only a global phase relative to Chapter 8

let prep = QuantumCircuit(qubits: 3)
prep.ry(theta, 0); prep.rz(phi, 0)
print("\nafter preparing q0 = psi:", pretty(prep.run(), qubits: 3))
prep.h(1); prep.cx(1, 2)
print("after Bell pair on q1,q2:", pretty(prep.run(), qubits: 3))

// ------------------------------------------------------------
// §2 — Alice's Bell-basis rotation
// ------------------------------------------------------------

let qc = QuantumCircuit(qubits: 3)
qc.ry(theta, 0); qc.rz(phi, 0)
qc.h(1); qc.cx(1, 2)
qc.cx(0, 1); qc.h(0)
let bellBasisState = qc.run()
print("\nafter cx(0,1); h(0):")
for row in 0..<4 {
    print(" ", pretty(StateVector([bellBasisState[2 * row], bellBasisState[2 * row + 1]]), qubits: 1)
        .replacingOccurrences(of: "|0⟩", with: "|\(bits(row, width: 2))0⟩")
        .replacingOccurrences(of: "|1⟩", with: "|\(bits(row, width: 2))1⟩"))
}
// magnitudes 0.4330 where the last two bits agree, 0.2500 where they differ

// ------------------------------------------------------------
// §3 — The four branches, via projectors
// ------------------------------------------------------------

let branchCorrections: [String: Matrix] = [
    "00": Matrix.identity(size: 2),
    "01": PauliXGate.matrix,
    "10": PauliZGate.matrix,
    "11": PauliZGate.matrix * PauliXGate.matrix    // apply X, then Z
]

print("\nab   P(ab)    fidelity")
for a in 0...1 {
    for b in 0...1 {
        let label = "\(a)\(b)"
        let projector = (Ket(label) * Bra(label)) ⊗ Matrix.identity(size: 2)
        var projected = bellBasisState
        projected.apply(projector)    // apply(_:) renormalises
        let base = a * 4 + b * 2
        var bobBranch = StateVector([projected[base], projected[base + 1]])
        let probAB = bellBasisState[base].magnitudeSquared + bellBasisState[base + 1].magnitudeSquared
        if let correction = branchCorrections[label] { bobBranch.apply(correction) }
        let fidelity = (bobBranch† * psi).magnitudeSquared
        print("\(label)   \(String(format: "%.4f", probAB))    \(String(format: "%.4f", fidelity))")
    }
}
// P(ab) = ¼ for every branch, independent of ψ; every branch reaches fidelity 1

// ------------------------------------------------------------
// §4 — Deferred measurement
// ------------------------------------------------------------

qc.cx(1, 2)                     // X^b
qc.h(2); qc.cx(0, 2); qc.h(2)   // Z^a, as CZ(0,2)
let finalState = qc.run()
print("\nfinal state:", pretty(finalState, qubits: 3))

let expectedFactored = (Ket.plus ⊗ Ket.plus) ⊗ psi
let maxDiff = (0..<8).map { (finalState[$0] - expectedFactored[$0]).magnitude }.max() ?? 0
print("matches |+⟩⊗|+⟩⊗|ψ⟩ to within", String(format: "%.1e", maxDiff))
// the register factors: q0, q1 end in |+⟩, q2 ends in |ψ⟩

// ------------------------------------------------------------
// §5 — No cloning, and what the shots show
// ------------------------------------------------------------

func marginal(_ state: StateVector, bit: Int) -> [Double] {
    var p = [0.0, 0.0]
    for (i, prob) in state.probabilities.enumerated() { p[(i >> (2 - bit)) & 1] += prob }
    return p
}
print("\nq2 (Bob) marginal:   ", marginal(finalState, bit: 2).map { String(format: "%.4f", $0) })
print("psi probabilities:   ", psi.probabilities.map { String(format: "%.4f", $0) })
print("q0 (Alice) marginal: ", marginal(finalState, bit: 0).map { String(format: "%.4f", $0) })
// Bob's marginal is |ψ|²; Alice's is a fair coin — the payload left q0

let shots = qc.measure(shots: 1000)
print("\n1000 shots (q0 q1 q2):", shots.sortedCounts.map { "\($0.state): \($0.count)" })
// about 250 per ab prefix, split roughly 3-to-1 on the last bit

// ------------------------------------------------------------
// §6 — Bloch spheres of every branch
// ------------------------------------------------------------

func branchState(_ label: String) -> StateVector {
    var s = psi
    if let correction = branchCorrections[label] { s.apply(correction) }
    return s
}

let branchLabels = ["00", "01", "10", "11"]
print("\nBloch points before Bob's classical bits arrive:")
for label in branchLabels {
    print(" ab = \(label):", card(BlochVector(branchState(label), qubit: 0)))
}
let bobCorrected = BlochVector(finalState, qubit: 2)
print(" Bob, corrected:", card(bobCorrected))
// X flips y and z, Z flips x and y; Bob lands back on ψ

// ------------------------------------------------------------
// §7 — Superdense coding
// ------------------------------------------------------------

let sdMessages: [(String, (QuantumCircuit) -> Void)] = [
    ("00", { _ in }),
    ("01", { $0.x(0) }),
    ("10", { $0.z(0) }),
    ("11", { $0.z(0); $0.x(0) })
]

print("\nsent  decoded  P")
for (label, encode) in sdMessages {
    let sdc = QuantumCircuit(qubits: 2)
    sdc.h(0); sdc.cx(0, 1)
    encode(sdc)
    sdc.cx(0, 1); sdc.h(0)
    let probs = sdc.run().probabilities
    if let index = probs.firstIndex(where: { $0 > 0.999 }) {
        print(" \(label)     \(bits(index, width: 2))    \(String(format: "%.4f", probs[index]))")
    }
}

let bellBasis = sdMessages.map { label, encode -> (String, StateVector) in
    let sdc = QuantumCircuit(qubits: 2)
    sdc.h(0); sdc.cx(0, 1); encode(sdc)
    return (label, sdc.run())
}
print("\nGram matrix |<Bell_i|Bell_j>|:")
for (li, si) in bellBasis {
    print("  \(li):", bellBasis.map { String(format: "%.2f", (si† * $0.1).magnitude) }.joined(separator: "  "))
}
// the identity: the four encodings are orthonormal, so decoding never errs

// ------------------------------------------------------------
// §8 — Live view
// ------------------------------------------------------------
// ψ, the four branches Bob could hold, and Bob's corrected qubit.
// Stateless views (no @State) — required for page code.

struct TeleportationView: View {
    let psi: BlochVector
    let branches: [(String, BlochVector)]
    let bob: BlochVector

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                BlochSphereView(label: "|ψ⟩ (Alice)", bloch: psi, size: 150)
                BlochSphereView(label: "Bob, corrected", bloch: bob, size: 150)
            }
            HStack(spacing: 8) {
                ForEach(branches.indices, id: \.self) { i in
                    BlochSphereView(label: branches[i].0, bloch: branches[i].1, size: 130)
                }
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    TeleportationView(
        psi: BlochVector(psi, qubit: 0),
        branches: branchLabels.map { ("ab = \($0)", BlochVector(branchState($0), qubit: 0)) },
        bob: bobCorrected
    )
    .frame(width: 600, height: 420)
)

//: [Next](@next)
