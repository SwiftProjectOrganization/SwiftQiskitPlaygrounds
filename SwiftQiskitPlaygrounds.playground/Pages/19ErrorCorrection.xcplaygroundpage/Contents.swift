//: [Previous](@previous)
/*:
 # Quantum Error Correction

 The 3-qubit bit-flip code: one logical qubit spread over three, a syndrome that names the
 error without reading α or β, a correction that never measures, and the point where a
 distance-3 code breaks.

 - Register: q0 holds |ψ⟩, `cx(0,1); cx(0,2)` encodes it as α|000⟩ + β|111⟩ (not cloning).
 - Syndrome ancillas q3, q4 learn the parities q0⊕q1 and q1⊕q2, and nothing else.
 - SwiftQiskit has no Toffoli with mixed controls, so the correction is a 32 × 32
   permutation matrix applied with `apply(_:)`.
 - A continuous `rx(θ)` error is digitized exactly: fidelity 1 for every θ, syndrome
   weights cos²(θ/2) and sin²(θ/2).
 - Two simultaneous errors fool the code silently; p_L = 3p² − 2p³.
 - Conjugating with `h` turns the same code into a phase-flip code (HZH = X).
 - A second, equivalent circuit uses no ancillas: decode, then a Toffoli built from CCZ.

 Limit: the correction is applied coherently to every branch rather than measuring the
 syndrome and branching on the result.

 Follows Chapter 19 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func bits(_ value: Int, width: Int) -> String {
    let s = String(value, radix: 2)
    return String(repeating: "0", count: max(0, width - s.count)) + s
}

func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-9 }
        .map { "|\(bits($0, width: qubits))⟩: \(state[$0])" }
        .joined(separator: "   ")
}

func card(_ bloch: BlochVector) -> String {
    String(format: "x %+.4f  y %+.4f  z %+.4f  |r| %.4f", bloch.x, bloch.y, bloch.z, bloch.magnitude)
}

let theta = Double.pi / 3
let phi = Double.pi / 4

let psiOnly: StateVector = {
    let qc = QuantumCircuit(qubits: 1)
    qc.ry(theta, 0); qc.rz(phi, 0)
    return qc.run()
}()
let zeroKet = StateVector([Complex(1), .zero])

// ------------------------------------------------------------
// §1 — Encoding one qubit into three
// ------------------------------------------------------------

print("|ψ⟩ on q0:", pretty(psiOnly, qubits: 1))
let encoded = QuantumCircuit(qubits: 3)
encoded.ry(theta, 0); encoded.rz(phi, 0)
encoded.cx(0, 1); encoded.cx(0, 2)
print("encoded (α|000⟩+β|111⟩):", pretty(encoded.run(), qubits: 3))
// entangled, not cloned

// ------------------------------------------------------------
// §2 — Injecting a bit-flip error
// ------------------------------------------------------------

let errored = QuantumCircuit(qubits: 3)
errored.ry(theta, 0); errored.rz(phi, 0)
errored.cx(0, 1); errored.cx(0, 2)
errored.x(1)
print("\nerror on q1:", pretty(errored.run(), qubits: 3))
// one bit disagrees with the other two

// ------------------------------------------------------------
// §3 — The syndrome and its correction
// ------------------------------------------------------------

func syndromeCircuit(errors: [Int]) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 5)
    qc.ry(theta, 0); qc.rz(phi, 0)
    qc.cx(0, 1); qc.cx(0, 2)
    for q in errors { qc.x(q) }
    qc.cx(0, 3); qc.cx(1, 3)    // q3 ← q0 ⊕ q1
    qc.cx(1, 4); qc.cx(2, 4)    // q4 ← q1 ⊕ q2
    return qc
}

let cases: [(String, [Int])] = [("none", []), ("q0", [0]), ("q1", [1]), ("q2", [2])]

print("\nerror   syndrome (q3 q4)   P")
for (name, errs) in cases {
    let state = syndromeCircuit(errors: errs).run()
    var pBySyndrome = [String: Double]()
    for i in 0..<32 { pBySyndrome[String(bits(i, width: 5).suffix(2)), default: 0] += state.probabilities[i] }
    if let top = pBySyndrome.max(by: { $0.value < $1.value }) {
        print("\(name)     \(top.key)              \(String(format: "%.4f", top.value))")
    }
}
// none 00, q0 10, q1 11, q2 01 — each with certainty

// The correction as a 32 × 32 permutation: flip the accused data qubit.
var correction = Matrix(rows: 32, cols: 32)
for i in 0..<32 {
    let b = bits(i, width: 5).map { Int(String($0)) ?? 0 }
    var c = b
    switch (b[3], b[4]) {
    case (1, 0): c[0] = 1 - c[0]    // syndrome 10 accuses q0
    case (1, 1): c[1] = 1 - c[1]    // syndrome 11 accuses q1
    case (0, 1): c[2] = 1 - c[2]    // syndrome 01 accuses q2
    default: break
    }
    correction[c[0] * 16 + c[1] * 8 + c[2] * 4 + c[3] * 2 + c[4], i] = Complex(1)
}
print("\ncorrection matrix is unitary:", correction† * correction == Matrix.identity(size: 32))

let syndromeIndex: [String: Int] = ["none": 0, "q0": 2, "q1": 3, "q2": 1]

func fidelity(_ state: StateVector, to expected: StateVector) -> Double {
    var overlap = Complex.zero
    for i in 0..<state.dimension { overlap = overlap + state[i].conjugate * expected[i] }
    return overlap.magnitudeSquared
}

func withDecode(errors: [Int]) -> QuantumCircuit {
    let qc = syndromeCircuit(errors: errors)
    qc.apply(correction)
    qc.cx(0, 2); qc.cx(0, 1)    // decode: undo the encoding
    return qc
}

print("\nerror   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩")
for (name, errs) in cases {
    var syndromeAmps = Array(repeating: Complex.zero, count: 4)
    syndromeAmps[syndromeIndex[name] ?? 0] = Complex(1)
    let expected = psiOnly ⊗ zeroKet ⊗ zeroKet ⊗ StateVector(syndromeAmps)
    print("\(name)     \(String(format: "%.4f", fidelity(withDecode(errors: errs).run(), to: expected)))")
}
// every single-qubit error is corrected exactly

// ------------------------------------------------------------
// §4 — Continuous errors, digitized exactly
// ------------------------------------------------------------

print("\nθ       fidelity   P(syndrome none)  P(syndrome q0)")
for (name, t) in [("0    ", 0.0), ("π/6  ", Double.pi / 6), ("π/3  ", Double.pi / 3),
                  ("π/2  ", Double.pi / 2), ("π    ", Double.pi)] {
    let qc = QuantumCircuit(qubits: 5)
    qc.ry(theta, 0); qc.rz(phi, 0)
    qc.cx(0, 1); qc.cx(0, 2)
    qc.rx(t, 0)
    qc.cx(0, 3); qc.cx(1, 3)
    qc.cx(1, 4); qc.cx(2, 4)
    qc.apply(correction)
    qc.cx(0, 2); qc.cx(0, 1)
    let state = qc.run()

    let ancilla = StateVector([Complex(cos(t / 2)), .zero, Complex(0, -sin(t / 2)), .zero])
    let expected = psiOnly ⊗ zeroKet ⊗ zeroKet ⊗ ancilla
    var pNone = 0.0, pQ0 = 0.0
    for i in 0..<32 {
        let suffix = bits(i, width: 5).suffix(2)
        if suffix == "00" { pNone += state.probabilities[i] }
        if suffix == "10" { pQ0 += state.probabilities[i] }
    }
    print("\(name)   \(String(format: "%.4f", fidelity(state, to: expected)))     \(String(format: "%.4f", pNone))            \(String(format: "%.4f", pQ0))")
}
// fidelity 1 for every θ; the syndrome records cos²(θ/2) and sin²(θ/2)

// ------------------------------------------------------------
// §5 — Where a distance-3 code breaks
// ------------------------------------------------------------

// |ψ⟩ = |1⟩, X errors on q0 AND q1: the syndrome wrongly accuses q2.
let twoErrors = QuantumCircuit(qubits: 5)
twoErrors.x(0)
twoErrors.cx(0, 1); twoErrors.cx(0, 2)
twoErrors.x(0); twoErrors.x(1)
twoErrors.cx(0, 3); twoErrors.cx(1, 3)
twoErrors.cx(1, 4); twoErrors.cx(2, 4)
twoErrors.apply(correction)
twoErrors.cx(0, 2); twoErrors.cx(0, 1)
var decoded = [0.0, 0.0]
for (i, p) in twoErrors.run().probabilities.enumerated() { decoded[i >> 4] += p }
print("\n|ψ⟩ = |1⟩, errors on q0 AND q1: decoded P(0) = \(String(format: "%.4f", decoded[0]))   P(1) = \(String(format: "%.4f", decoded[1]))")
// P(0) = 1: a confident, silent miscorrection

func minorityCorrectionFails(_ flippedQubits: [Int]) -> Bool {
    var flips = [0, 0, 0]
    for q in flippedQubits { flips[q] = 1 }
    var corrected = flips
    switch (flips[0] ^ flips[1], flips[1] ^ flips[2]) {
    case (1, 0): corrected[0] ^= 1
    case (1, 1): corrected[1] ^= 1
    case (0, 1): corrected[2] ^= 1
    default: break
    }
    return corrected != [0, 0, 0]
}

func logicalErrorRate(_ p: Double) -> Double {
    var total = 0.0
    for mask in 0..<8 {
        let pattern = (0..<3).filter { (mask >> $0) & 1 == 1 }
        if minorityCorrectionFails(pattern) {
            total += pow(p, Double(pattern.count)) * pow(1 - p, Double(3 - pattern.count))
        }
    }
    return total
}

print("\np       p_L (enumerated)   formula 3p²−2p³")
for p in [0.05, 0.1, 0.2, 0.3, 0.5] {
    let formula = 3 * p * p - 2 * p * p * p
    print("\(String(format: "%.2f", p))    \(String(format: "%.4f", logicalErrorRate(p)))              \(String(format: "%.4f", formula))")
}
// beats the unencoded rate p only below p = ½

// ------------------------------------------------------------
// §6 — Phase flips, by conjugation
// ------------------------------------------------------------

print("\nphase-flip error   fidelity to |ψ⟩⊗|00⟩⊗|syndrome⟩")
for (name, errs) in cases {
    let qc = QuantumCircuit(qubits: 5)
    qc.ry(theta, 0); qc.rz(phi, 0)
    qc.cx(0, 1); qc.cx(0, 2)
    for q in 0..<3 { qc.h(q) }
    for q in errs { qc.z(q) }
    for q in 0..<3 { qc.h(q) }    // HZH = X: a phase flip becomes a bit flip
    qc.cx(0, 3); qc.cx(1, 3)
    qc.cx(1, 4); qc.cx(2, 4)
    qc.apply(correction)
    qc.cx(0, 2); qc.cx(0, 1)
    var syndromeAmps = Array(repeating: Complex.zero, count: 4)
    syndromeAmps[syndromeIndex[name] ?? 0] = Complex(1)
    let expected = psiOnly ⊗ zeroKet ⊗ zeroKet ⊗ StateVector(syndromeAmps)
    print("\(name)     \(String(format: "%.4f", fidelity(qc.run(), to: expected)))")
}

// ------------------------------------------------------------
// §7 — A circuit with no ancillas: Toffoli from CCZ
// ------------------------------------------------------------
// Decoding again routes the syndrome onto q1, q2 themselves; a Toffoli with controls
// q1, q2 and target q0 then fixes q0. CCZ comes from t, tdg and cx (Chapter 15).

func ccz(_ qc: QuantumCircuit, _ a: Int, _ b: Int, _ c: Int) {
    qc.cx(b, c); qc.tdg(c); qc.cx(a, c); qc.t(c); qc.cx(b, c); qc.tdg(c); qc.cx(a, c)
    qc.t(b); qc.t(c); qc.cx(a, b); qc.t(a); qc.tdg(b); qc.cx(a, b)
}

func compactCircuit(errors: [Int]) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 3)
    qc.ry(theta, 0); qc.rz(phi, 0)
    qc.cx(0, 1); qc.cx(0, 2)
    for q in errors { qc.x(q) }
    qc.cx(0, 1); qc.cx(0, 2)                      // decode: the syndrome lands on q1, q2
    qc.h(0); ccz(qc, 1, 2, 0); qc.h(0)            // Toffoli(controls q1, q2; target q0)
    return qc
}

print("\ncompact circuit, q0 Bloch point per error:")
for (name, errs) in cases {
    print(" ", name, card(BlochVector(compactCircuit(errors: errs).run(), qubit: 0)))
}
// 0.6124, 0.6124, 0.5000 for every case: q0 always returns to |ψ⟩
let compactShots = compactCircuit(errors: [1]).measure(shots: 1000)
print("error on q1, 1000 shots (q0 q1 q2):", compactShots.sortedCounts.map { "\($0.state): \($0.count)" })
// about 750 × 010 and 250 × 110: |ψ|² on q0, syndrome 10 fixed

// ------------------------------------------------------------
// §8 — Bloch spheres, and what's next
// ------------------------------------------------------------

let noCorrection = QuantumCircuit(qubits: 3)
noCorrection.ry(theta, 0); noCorrection.rz(phi, 0)
noCorrection.cx(0, 1); noCorrection.cx(0, 2)
noCorrection.x(0)
noCorrection.cx(0, 1); noCorrection.cx(0, 2)
let blochPrepared = BlochVector(psiOnly, qubit: 0)
let blochUncorrected = BlochVector(noCorrection.run(), qubit: 0)
let blochCorrected = BlochVector(compactCircuit(errors: [0]).run(), qubit: 0)
print("\n|ψ⟩ prepared:         ", card(blochPrepared))
print("q0, error, no fix:   ", card(blochUncorrected))
print("q0, error, corrected:", card(blochCorrected))
// the middle point is X|ψ⟩; the last lands back on the first

// ------------------------------------------------------------
// §9 — Live view
// ------------------------------------------------------------
// Stateless views (no @State) — required for page code.

struct ErrorCorrectionView: View {
    let prepared: BlochVector
    let uncorrected: BlochVector
    let corrected: BlochVector

    var body: some View {
        HStack(spacing: 8) {
            BlochSphereView(label: "|ψ⟩ prepared", bloch: prepared, size: 170)
            BlochSphereView(label: "error, no correction", bloch: uncorrected, size: 170)
            BlochSphereView(label: "error, corrected", bloch: corrected, size: 170)
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    ErrorCorrectionView(prepared: blochPrepared, uncorrected: blochUncorrected, corrected: blochCorrected)
        .frame(width: 600, height: 260)
)

//: [Next](@next)
