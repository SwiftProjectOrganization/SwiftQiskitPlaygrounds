//: [Previous](@previous)
/*:
 # Superposition across a register

 One `H` gate buys two simultaneous amplitudes; `H` on `n` qubits buys `2ⁿ`. This page scales
 superposition from one qubit to a 4-qubit register.

 - `H` on every qubit of `|0000⟩` gives a **uniform** superposition over all 16 basis states.
 - **Qubit 0 is the leftmost bit** of every basis label.
 - `H` on `k` of `n` qubits gives `2ᵏ` equally likely outcomes.
 - A uniform superposition is **one state**, not a random pick: a second `H` layer undoes it.

 Follows Chapter 10 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func binaryLabel(_ index: Int, qubits: Int) -> String {
    let raw = String(index, radix: 2)
    return String(repeating: "0", count: max(0, qubits - raw.count)) + raw
}

// ------------------------------------------------------------
// §1 — Every qubit in superposition
// ------------------------------------------------------------
// Four independent |+⟩ states: every basis state gets amplitude (1/√2)⁴ = 1/4.

let qc = QuantumCircuit(qubits: 4)
qc.h(0); qc.h(1); qc.h(2); qc.h(3)
let state = qc.run()
print("amplitudes:", state.amplitudes)
print("probabilities:", state.probabilities)
// sixteen amplitudes ≈ 0.25, sixteen probabilities ≈ 0.0625

// ------------------------------------------------------------
// §2 — Reading multi-qubit labels
// ------------------------------------------------------------
// X on q1 alone flips the *second* character from the left.

let qcX = QuantumCircuit(qubits: 4)
qcX.x(1)
for (i, p) in qcX.run().probabilities.enumerated() where p > 1e-9 {
    print("X on q1 alone ->", "|\(binaryLabel(i, qubits: 4))⟩:", p)
}
// |0100⟩: 1.0

// ------------------------------------------------------------
// §3 — Partial superposition
// ------------------------------------------------------------
// H on k of n qubits: 2ᵏ outcomes, the untouched qubits stay frozen at 0.

let partial = QuantumCircuit(qubits: 4)
partial.h(0); partial.h(2)
for (i, p) in partial.run().probabilities.enumerated() where p > 1e-9 {
    print("partial |\(binaryLabel(i, qubits: 4))⟩:", p)
}
// |0000⟩, |0010⟩, |1000⟩, |1010⟩ — each ≈ 0.25

// ------------------------------------------------------------
// §4 — Confirming uniformity by measurement
// ------------------------------------------------------------
// Expected count per outcome is 100, with σ_count = √(N·p(1−p)).

let result = qc.measure(shots: 1600)
let counts = result.sortedCounts.map(\.count)
print("sortedCounts (1600 shots):", result.sortedCounts)
print("min:", counts.min() ?? -1, "max:", counts.max() ?? -1)

let p16 = 1.0 / 16.0
let sigmaCount = sqrt(1600.0 * p16 * (1 - p16))
print(String(format: "predicted sigma_count = %.2f, 95%% band ±%.1f around 100",
             sigmaCount, 1.96 * sigmaCount))
// 9.68, ±19.0 — every count should land roughly within 81…119

let result20 = qc.measure(shots: 20)
print("20-shot run, keys present:", result20.counts.keys.count, "of 16")
// typically fewer than 16: missing outcomes are absent, not impossible

// ------------------------------------------------------------
// §5 — What a uniform superposition costs
// ------------------------------------------------------------

for n in 1...8 {
    let dim = QuantumCircuit(qubits: n).run().dimension
    print("qubits \(n)  dimension \(dim)  operator entries \(dim * dim)")
}
// 2, 4, 8, … 256 amplitudes; 4, 16, … 65,536 operator entries

// ------------------------------------------------------------
// §6 — One state, not a random choice
// ------------------------------------------------------------
// A second H layer returns exactly to |0000⟩ — impossible for a classical mixture.

let back = QuantumCircuit(qubits: 4)
back.h(0); back.h(1); back.h(2); back.h(3)
back.h(0); back.h(1); back.h(2); back.h(3)
print("4×H; 4×H probabilities:", back.run().probabilities)
// [≈1.0, 0, 0, …]

// X after the full H layer permutes equal amplitudes: probabilities do not change.
let shifted = QuantumCircuit(qubits: 4)
shifted.h(0); shifted.h(1); shifted.h(2); shifted.h(3)
shifted.x(0)
print("X after 4×H probabilities:", shifted.run().probabilities)
// still sixteen entries ≈ 0.0625

// ------------------------------------------------------------
// §7 — Independent qubits, not entangled
// ------------------------------------------------------------

let blochVectors = (0..<4).map { BlochVector(state, qubit: $0) }
for (q, b) in blochVectors.enumerated() {
    print(String(format: "qubit %d  x %+.3f  y %+.3f  z %+.3f  |r| %.3f",
                 q, b.x, b.y, b.z, b.magnitude))
}
// all four: x +1, y 0, z 0, |r| = 1 — four separate |+⟩ states

// ------------------------------------------------------------
// §8 — Live view
// ------------------------------------------------------------
// Four Bloch spheres (one per qubit) above a histogram of the 1600-shot run.
// Stateless views (no @State) — required for page code.

struct RegisterHistogram: View {
    let result: SimulationResult

    var body: some View {
        let sorted = result.sortedCounts
        let maxCount = max(sorted.map(\.count).max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 4) {
            Text("Measurement counts (\(result.shots) shots)")
                .font(.headline)
            Text("Bars are scaled to the largest count: read the numbers.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(sorted, id: \.state) { entry in
                    VStack(spacing: 2) {
                        Text("\(entry.count)")
                            .font(.system(size: 8, design: .monospaced))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 120 * CGFloat(entry.count) / CGFloat(maxCount))
                        Text(entry.state)
                            .font(.system(size: 8, design: .monospaced))
                    }
                }
            }
            .frame(height: 160, alignment: .bottom)
        }
        .padding(8)
    }
}

struct SuperpositionView: View {
    let blochVectors: [BlochVector]
    let result: SimulationResult

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(blochVectors.indices, id: \.self) { q in
                    BlochSphereView(label: "q\(q)", bloch: blochVectors[q], size: 150)
                }
            }
            RegisterHistogram(result: result)
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    SuperpositionView(blochVectors: blochVectors, result: result)
        .frame(width: 720, height: 560)
)

//: [Next](@next)
