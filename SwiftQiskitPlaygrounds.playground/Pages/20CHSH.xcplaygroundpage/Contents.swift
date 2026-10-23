//: [Previous](@previous)
/*:
 # Bell Tests: The CHSH Inequality

 Why entanglement isn't "hidden classical information". Any local-hidden-variable strategy
 keeps `S = E(a,b) − E(a,b′) + E(a′,b) + E(a′,b′)` at or below 2 in magnitude; a Bell pair
 reaches 2√2.

 - All 16 deterministic strategies are enumerated; a randomized model only averages them.
 - `A(θ) = cos θ·Z + sin θ·X` is built with `Matrix` `+` and scalar `*`.
 - Measuring `A(θ)` is `ry(−θ)` plus a computational-basis read, pinned against ⟨ψ|A|ψ⟩.
 - Each correlator is computed exactly (`ψ† * (A ⊗ A) * ψ`) and by sampling shots.
 - At a = 0, a′ = π/2, b = π/4, b′ = 3π/4 the exact S is 2√2 ≈ 2.8284.
 - Controls: a product state gives √2, and a sweep never beats Tsirelson's 2√2.
 - No signalling: Alice's angle never moves Bob's marginal or his reduced Bloch vector.

 Limit: the shared-direction model and the 16-strategy enumeration are plain Swift, not circuits.

 Follows Chapter 20 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func fmt(_ d: Double) -> String { String(format: "%.4f", d) }

let a = 0.0, ap = Double.pi / 2, b = Double.pi / 4, bp = 3 * Double.pi / 4

// ------------------------------------------------------------
// §1 — The classical bound, enumerated
// ------------------------------------------------------------

var maxClassicalS = 0
for sa in [-1, 1] {
    for sap in [-1, 1] {
        for sb in [-1, 1] {
            for sbp in [-1, 1] {
                let s = sa * sb - sa * sbp + sap * sb + sap * sbp
                maxClassicalS = max(maxClassicalS, abs(s))
            }
        }
    }
}
print("deterministic strategies checked: 16")
print("max |S| over all of them: \(maxClassicalS)")    // 2

func lhvSign(_ setting: Double, _ lambda: Double) -> Double {
    cos(setting - lambda) >= 0 ? 1.0 : -1.0
}

func lhvCorrelator(_ x: Double, _ y: Double, trials: Int) -> Double {
    var sum = 0.0
    for _ in 0..<trials {
        let lambda = Double.random(in: 0..<(2 * Double.pi))
        sum += lhvSign(x, lambda) * lhvSign(y, lambda)
    }
    return sum / Double(trials)
}

let lhvS = lhvCorrelator(a, b, trials: 200_000) - lhvCorrelator(a, bp, trials: 200_000)
    + lhvCorrelator(ap, b, trials: 200_000) + lhvCorrelator(ap, bp, trials: 200_000)
print("shared-direction model S ≈ \(fmt(lhvS))")
// about 1.998 (statistical, ±0.01): it saturates the bound, it doesn't beat it

// ------------------------------------------------------------
// §2 — Measuring along a tilted axis
// ------------------------------------------------------------

func A(_ theta: Double) -> Matrix {
    let Z = Matrix([[Complex(1), Complex(0)], [Complex(0), Complex(-1)]])
    let X = Matrix([[Complex(0), Complex(1)], [Complex(1), Complex(0)]])
    return cos(theta) * Z + sin(theta) * X
}

let testQubit = QuantumCircuit(qubits: 1)
testQubit.ry(Double.pi / 3, 0)
testQubit.rz(Double.pi / 4, 0)
let testPsi = testQubit.run()

print("\nangle    exact ⟨A(θ)⟩   via ry(−θ)+Z")
for angle in [0.0, Double.pi / 6, Double.pi / 4, Double.pi / 2] {
    let exact = (testPsi† * A(angle) * testPsi).real
    var rotated = testPsi
    rotated.apply(RYGate.matrix(theta: -angle))
    let viaMeasurement = rotated.probabilities[0] - rotated.probabilities[1]
    print("\(fmt(angle))   \(fmt(exact))         \(fmt(viaMeasurement))")
}
// 0.5000 (⟨Z⟩) at θ = 0 through 0.6124 (⟨X⟩) at θ = π/2; the columns agree

// ------------------------------------------------------------
// §3 — A Bell pair's correlations, two ways
// ------------------------------------------------------------

let bell = QuantumCircuit(qubits: 2)
bell.h(0); bell.cx(0, 1)
let bellState = bell.run()

func exactCorrelator(_ x: Double, _ y: Double, state: StateVector) -> Double {
    (state† * (A(x) ⊗ A(y)) * state).real
}

func sampledCorrelator(_ x: Double, _ y: Double, shots: Int) -> Double {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.cx(0, 1)
    qc.ry(-x, 0); qc.ry(-y, 1)
    var total = 0.0
    for (outcome, count) in qc.measure(shots: shots).counts {
        let chars = Array(outcome)
        total += (chars[0] == chars[1] ? 1.0 : -1.0) * Double(count)
    }
    return total / Double(shots)
}

let settings: [(String, Double, Double)] = [
    ("(a, b)  ", a, b), ("(a, b') ", a, bp), ("(a', b) ", ap, b), ("(a', b')", ap, bp)
]
print("\nsetting pair    exact E    sampled E   cos(a−b)")
for (name, x, y) in settings {
    print("\(name)   \(fmt(exactCorrelator(x, y, state: bellState)))    \(fmt(sampledCorrelator(x, y, shots: 4000)))     \(fmt(cos(x - y)))")
}
// the sampled column jitters by a few hundredths at 4000 shots

// ------------------------------------------------------------
// §4 — S = 2√2
// ------------------------------------------------------------

func chshS(_ state: StateVector) -> Double {
    exactCorrelator(a, b, state: state) - exactCorrelator(a, bp, state: state)
        + exactCorrelator(ap, b, state: state) + exactCorrelator(ap, bp, state: state)
}

print("\nexact S = \(fmt(chshS(bellState)))   (2√2 = \(fmt(2 * sqrt(2))))")
let sampledS = sampledCorrelator(a, b, shots: 4000) - sampledCorrelator(a, bp, shots: 4000)
    + sampledCorrelator(ap, b, shots: 4000) + sampledCorrelator(ap, bp, shots: 4000)
print("sampled S = \(fmt(sampledS))")

// ------------------------------------------------------------
// §5 — Controls: entanglement is necessary, and Tsirelson's bound
// ------------------------------------------------------------

let product = QuantumCircuit(qubits: 2)
product.h(0); product.h(1)
print("\nproduct state |+⟩⊗|+⟩: S = \(fmt(chshS(product.run())))")    // √2

var maxSweptS = 0.0
var probe = 0.0
while probe < Double.pi {
    let s = exactCorrelator(0, probe, state: bellState) - exactCorrelator(0, probe + Double.pi / 2, state: bellState)
        + exactCorrelator(Double.pi / 2, probe, state: bellState)
        + exactCorrelator(Double.pi / 2, probe + Double.pi / 2, state: bellState)
    maxSweptS = max(maxSweptS, abs(s))
    probe += 0.001
}
print("max |S| over the b-sweep: \(fmt(maxSweptS))   (Tsirelson: \(fmt(2 * sqrt(2))))")

// ------------------------------------------------------------
// §6 — No signalling
// ------------------------------------------------------------

print("\nAlice's ry(-a)   Bob's P(q1=0)   q1 Bloch |r|")
for angle in [0.0, Double.pi / 6, Double.pi / 4, Double.pi / 2, Double.pi] {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.cx(0, 1)
    qc.ry(-angle, 0)
    let state = qc.run()
    let pQ1zero = state.probabilities[0] + state.probabilities[2]    // q0 is the MSB
    print("\(fmt(angle))           \(fmt(pQ1zero))          \(fmt(BlochVector(state, qubit: 1).magnitude))")
}
// 0.5000 and |r| = 0 for every angle: Alice's choice never moves Bob's own data

// ------------------------------------------------------------
// §7 — The gap, plotted
// ------------------------------------------------------------

let steps = 8
let thetas = (0...steps).map { Double.pi * Double($0) / Double(steps) }
print("\nθ        quantum cos θ   classical line")
for t in thetas {
    print("\(fmt(t))    \(fmt(exactCorrelator(0, t, state: bellState)))          \(fmt(1 - 2 * t / Double.pi))")
}
// they agree only at 0, π/2, π and differ most (about 0.207) near π/4 and 3π/4

let quantumCurve = (0...64).map { i -> CGPoint in
    let t = Double.pi * Double(i) / 64
    return CGPoint(x: t, y: exactCorrelator(0, t, state: bellState))
}
let classicalLine = [CGPoint(x: 0, y: 1), CGPoint(x: Double.pi, y: -1)]
let sampledPoints = thetas.map { CGPoint(x: $0, y: sampledCorrelator(0, $0, shots: 500)) }

PlaygroundPage.current.setLiveView(
    CHSHChartView(
        title: "E(θ) for a Bell pair vs. the best local model",
        xRange: 0...Double.pi,
        yRange: -1.1...1.1,
        series: [
            CHSHChartView.Series(label: "quantum cos θ", color: .blue, points: quantumCurve, isLine: true),
            CHSHChartView.Series(label: "classical 1 − 2θ/π", color: .red, points: classicalLine, isLine: true),
            CHSHChartView.Series(label: "500-shot samples", color: .green, points: sampledPoints, isLine: false)
        ]
    )
    .padding()
)

//: [Next](@next)
