//: [Previous](@previous)
/*:
 # Measurement, shots and statistics

 Measurement is the only channel out of a quantum computer. What comes out is one classical
 bit string, chosen at random by the **Born rule**: basis state `i` appears with probability
 `|amplitudeᵢ|²`.

 - Measurement is **not reversible**: it collapses the state onto the outcome.
 - Measurement is **basis dependent**: "measure" means "measure in the Z basis".
 - One shot gives one bit; only an **ensemble** of shots estimates the probabilities,
   with an error that shrinks like 1/√N.

 Follows Chapter 9 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Exact vs. sampled: run() vs measure(shots:)
// ------------------------------------------------------------
// run() is the simulator's privileged view: exact, deterministic. measure(shots:) is what
// a real device can do, and it jitters.

let qcH = QuantumCircuit(qubits: 1)
qcH.h(0)
print("run() call 1:", qcH.run().probabilities)
print("run() call 2:", qcH.run().probabilities)
// identical, ≈ [0.5, 0.5]

for i in 1...6 {
    print("measure(shots: 1000) run \(i):", qcH.measure(shots: 1000).sortedCounts)
}
// six different splits, all within roughly 470–530

// ------------------------------------------------------------
// §2 — Collapse, seen once
// ------------------------------------------------------------

print("runAndMeasure() outcome:", qcH.runAndMeasure())

var sv = qcH.run()
print("before measure():", sv.probabilities)
let first = sv.measure()
print("measure() returned:", first, "probabilities now:", sv.probabilities)
let second = sv.measure()
print("measure() again returned:", second, "probabilities still:", sv.probabilities)
// the superposition is gone: [0, 1] or [1, 0], and measuring again changes nothing

// ------------------------------------------------------------
// §3 — Why shots jitter
// ------------------------------------------------------------
// Each shot is a coin flip with probability p, so the fraction of shots on an outcome has
// σ = √(p(1−p)/N): the 1/√N law.

for n in [10, 100, 1000, 10000] {
    var fractions: [Double] = []
    for _ in 0..<40 {
        let zeros = qcH.measure(shots: n).counts["0"] ?? 0
        fractions.append(Double(zeros) / Double(n))
    }
    let mean = fractions.reduce(0, +) / Double(fractions.count)
    let variance = fractions.map { pow($0 - mean, 2) }.reduce(0, +) / Double(fractions.count - 1)
    let predicted = sqrt(0.25 / Double(n))
    print(String(format: "N %6d  mean %.4f  observed σ %.4f  predicted σ %.4f",
                 n, mean, sqrt(variance), predicted))
}
// σ roughly halves every time N quadruples

let sigmaCount = sqrt(1000.0 * 0.5 * 0.5)
print(String(format: "N=1000: count σ %.2f, 95%% band ±%.1f counts around 500",
             sigmaCount, 1.96 * sigmaCount))
// 15.81, ±31.0

// ------------------------------------------------------------
// §4 — Reading a histogram honestly
// ------------------------------------------------------------
// counts has no entry at all for an outcome that never came up. run().probabilities
// always has one entry per basis state.

let bell = QuantumCircuit(qubits: 2)
bell.h(0); bell.cx(0, 1)
let bellResult = bell.measure(shots: 500)
print("Bell histogram (500 shots):", bellResult.sortedCounts.map { "|\($0.state)⟩: \($0.count)" },
      "key count:", bellResult.counts.keys.count)
// only |00⟩ and |11⟩ — two keys, not four
print("Bell exact probabilities:", bell.run().probabilities)
// ≈ [0.5, 0, 0, 0.5] — a missing bar is absent, not necessarily impossible

// ------------------------------------------------------------
// §5 — Unequal splits
// ------------------------------------------------------------
// RY(θ) gives p₀ = cos²(θ/2); sweeping θ recovers the curve from statistics alone.

for k in 0...4 {
    let theta = Double(k) * .pi / 4
    let c = QuantumCircuit(qubits: 1)
    c.ry(theta, 0)
    let p0 = c.run().probabilities[0]
    let measured = Double(c.measure(shots: 10000).counts["0"] ?? 0) / 10000
    print(String(format: "theta %.4f  cos²(theta/2) %.4f  run() p0 %.4f  measured p0 %.4f",
                 theta, pow(cos(theta / 2), 2), p0, measured))
}
// run() agrees with the formula; the measured column differs by about σ ≈ 0.005

let qcThird = QuantumCircuit(qubits: 1)
qcThird.ry(1.047, 0)
print("theta ≈ π/3 exact:", qcThird.run().probabilities)               // ≈ [0.75, 0.25]
print("theta ≈ π/3 10000 shots:", qcThird.measure(shots: 10000).sortedCounts)

// ------------------------------------------------------------
// §6 — Basis dependence
// ------------------------------------------------------------
// Nothing about the qubit changes; what changes is the question asked of it.

let qcHH = QuantumCircuit(qubits: 1)
qcHH.h(0); qcHH.h(0)
print("|+⟩ measured as-is:", qcH.measure(shots: 1000).counts)    // roughly 500 / 500
print("H before measuring:", qcHH.measure(shots: 1000).counts)   // ["0": 1000]

// ------------------------------------------------------------
// §7 — Beyond the app's 10,000-shot cap
// ------------------------------------------------------------

let big = Double(qcH.measure(shots: 100_000).counts["0"] ?? 0) / 100_000
print(String(format: "N 100000  p₀ %.4f  predicted σ %.5f", big, sqrt(0.25 / 100_000)))
// within a few thousandths of 0.5; σ ≈ 0.0016

// ------------------------------------------------------------
// §8 — Live view
// ------------------------------------------------------------
// Histograms drawn like the app's HistogramView: every bar is scaled against the largest
// count, so read the printed number, not the bar height.
// Stateless view (no @State) — required for page code.

struct HistogramCard: View {
    let title: String
    let result: SimulationResult

    var body: some View {
        let sorted = result.sortedCounts
        let maxCount = max(sorted.map(\.count).max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text("Measurement counts (\(result.shots) shots)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(sorted, id: \.state) { entry in
                    VStack(spacing: 2) {
                        Text("\(entry.count)")
                            .font(.system(size: 9, design: .monospaced))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor)
                            .frame(width: 22, height: 120 * CGFloat(entry.count) / CGFloat(maxCount))
                        Text("|\(entry.state)⟩")
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
            }
            .frame(height: 160, alignment: .bottom)
        }
        .padding(8)
        .frame(width: 260, alignment: .leading)
    }
}

let thirdCircuit = QuantumCircuit(qubits: 1)
thirdCircuit.ry(.pi / 3, 0)

let cards: [(title: String, result: SimulationResult)] = [
    ("H, 100 shots", qcH.measure(shots: 100)),
    ("H, 1000 shots", qcH.measure(shots: 1000)),
    ("H, 10000 shots", qcH.measure(shots: 10000)),
    ("RY(π/3), 10000 shots", thirdCircuit.measure(shots: 10000)),
    ("Bell, 500 shots", bell.measure(shots: 500))
]

struct MeasurementView: View {
    let cards: [(title: String, result: SimulationResult)]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(260)), count: 2), spacing: 16) {
            ForEach(cards, id: \.title) { card in
                HistogramCard(title: card.title, result: card.result)
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    MeasurementView(cards: cards)
        .frame(width: 580, height: 700)
)

//: [Next](@next)
