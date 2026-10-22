//: [Previous](@previous)
/*:
 # Oracles and Phase Kickback: Deutsch's Algorithm

 Is a 1-bit function f constant (f(0) = f(1)) or balanced (f(0) ≠ f(1))? One oracle query
 answers it, where a classical machine needs two.

 - The four 1-bit oracles are all built from `x` and `cx`.
 - The ancilla starts in `|−⟩`, an eigenvector of `X` with eigenvalue −1, so the oracle's
   value f(x) becomes a **sign**: `|x⟩|−⟩ → (−1)^f(x) |x⟩|−⟩`.
 - The two qubits never entangle: the phase genuinely sits on q0 (`|r| = 1` throughout).
 - The closing `h(0)` turns the sign into a certain bit.
 - Deutsch's 1985 circuit (ancilla in `|0⟩`) is conclusive only half the time.
 - One query buys one bit: the parity f(0) ⊕ f(1), not f(0) or f(1) alone.

 Limit: `measure(shots:)` samples the whole register — the verdict is the leftmost bit
 of the joint outcome.

 Follows Chapter 13 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func card(_ bloch: BlochVector) -> String {
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", bloch.x, bloch.y, bloch.z, bloch.magnitude)
}

func pOne(_ state: StateVector) -> Double {
    let p = state.probabilities
    return p[2] + p[3]    // probability that q0 (leftmost bit) reads 1
}

// ------------------------------------------------------------
// §1 — The four 1-bit oracles
// ------------------------------------------------------------

struct DeutschOracle {
    let name: String
    let isBalanced: Bool
    let apply: (QuantumCircuit) -> Void
}

let oracles: [DeutschOracle] = [
    DeutschOracle(name: "f(x) = 0  ", isBalanced: false) { _ in },
    DeutschOracle(name: "f(x) = 1  ", isBalanced: false) { $0.x(1) },
    DeutschOracle(name: "f(x) = x  ", isBalanced: true) { $0.cx(0, 1) },
    DeutschOracle(name: "f(x) = 1−x", isBalanced: true) { $0.cx(0, 1); $0.x(1) }
]

// Qubit 0 is the query register, qubit 1 the ancilla.
func deutschCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1); qc.h(0); qc.h(1)
    oracle(qc)
    qc.h(0)
    return qc
}

// ------------------------------------------------------------
// §2 — Preparing the phase register
// ------------------------------------------------------------

let prep = QuantumCircuit(qubits: 2)
prep.x(1); prep.h(0); prep.h(1)
print("after x(1),h(0),h(1):", prep.run().amplitudes)
// |+⟩|−⟩ = [0.5, -0.5, 0.5, -0.5]

var xMinus = Ket.minus
xMinus.apply(PauliXGate.matrix)
print("<-|X|-> =", Ket.minus† * xMinus)
// ≈ -1: |−⟩ is an eigenvector of X with eigenvalue −1

// ------------------------------------------------------------
// §3 — Phase kickback, stage by stage (f(x) = x)
// ------------------------------------------------------------

let walk = QuantumCircuit(qubits: 2)
walk.x(1)
print("after x(1):       ", walk.run().amplitudes)
walk.h(0); walk.h(1)
let afterPrep = walk.run()
print("after h(0),h(1):  ", afterPrep.amplitudes)
walk.cx(0, 1)
let afterOracle = walk.run()
print("after cx(0,1):    ", afterOracle.amplitudes)
// ancilla amplitudes unchanged; |10⟩ and |11⟩ swapped sign — the kickback
walk.h(0)
let afterFinalH = walk.run()
print("after final h(0): ", afterFinalH.amplitudes)

print("\nsign pattern after oracle (before final H):")
for oracle in oracles {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1); qc.h(0); qc.h(1)
    oracle.apply(qc)
    let s = qc.run()
    print(oracle.name, s.amplitudes.map { String(format: "%+.4f", $0.real) }, "probs", s.probabilities)
}
// constant: global sign (invisible); balanced: relative sign. All probabilities 0.25.

// ------------------------------------------------------------
// §4 — The register never entangles
// ------------------------------------------------------------

print("\nBloch cards through the f(x) = x run:")
let stages: [(String, StateVector)] = [
    ("after h,h:", afterPrep), ("after cx:  ", afterOracle), ("after H:   ", afterFinalH)
]
for (label, s) in stages {
    print(label, "q0", card(BlochVector(s, qubit: 0)), "  q1", card(BlochVector(s, qubit: 1)))
}
// |r| 1.000 on both qubits at every stage — unlike the Bell state's |r| 0

// ------------------------------------------------------------
// §5 — The closing H: sign becomes a certain bit
// ------------------------------------------------------------

print("\noracle       P(q0=1)  verdict     expected")
for oracle in oracles {
    let p = pOne(deutschCircuit(oracle: oracle.apply).run())
    let verdict = p > 0.5 ? "balanced" : "constant"
    let expected = oracle.isBalanced ? "balanced" : "constant"
    print("\(oracle.name)   \(String(format: "%.4f", p))   \(verdict)    \(expected)")
}

// Without the closing H the phase is unreadable: ~25% on every outcome.
print("\nno final H, 1000 shots each:")
for oracle in oracles {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(1); qc.h(0); qc.h(1); oracle.apply(qc)
    print(oracle.name, qc.measure(shots: 1000).sortedCounts.map { "\($0.state): \($0.count)" })
}

// ------------------------------------------------------------
// §6 — The wrong ancilla: Deutsch's 1985 original
// ------------------------------------------------------------

let bad0 = QuantumCircuit(qubits: 2)
bad0.h(0); bad0.cx(0, 1)
let bad0Bell = bad0.run()
print("\nancilla |0>, f(x)=x after cx: q0", card(BlochVector(bad0Bell, qubit: 0)),
      " probs", bad0Bell.probabilities)
// |r| 0 — a Bell state: the query was spent creating entanglement, not kickback
bad0.h(0)
print("ancilla |0>, f(x)=x final: P(q0=1) =", pOne(bad0.run()))
// 0.5 — a coin flip

let bad0Const = QuantumCircuit(qubits: 2)
bad0Const.h(0); bad0Const.h(0)
print("ancilla |0>, f(x)=0 final: P(q0=1) =", pOne(bad0Const.run()))
// 0.0 — q0 = 1 therefore proves "balanced"; q0 = 0 is inconclusive

let bad1 = QuantumCircuit(qubits: 2)
bad1.x(1); bad1.h(0); bad1.cx(0, 1); bad1.h(0)
print("ancilla |1>, f(x)=x probs:", bad1.run().probabilities)

let badPlus = QuantumCircuit(qubits: 2)
badPlus.h(0); badPlus.h(1); badPlus.cx(0, 1); badPlus.h(0)
print("ancilla |+>, f(x)=x probs:", badPlus.run().probabilities)
// only |−⟩ gives the deterministic version

// ------------------------------------------------------------
// §7 — Shot statistics
// ------------------------------------------------------------

let constResult = deutschCircuit(oracle: { $0.x(1) }).measure(shots: 1000)
print("\nf(x)=1 (constant):", constResult.sortedCounts.map { "|\($0.state)⟩: \($0.count)" })
let balResult = deutschCircuit(oracle: { $0.cx(0, 1) }).measure(shots: 1000)
print("f(x)=x (balanced):", balResult.sortedCounts.map { "|\($0.state)⟩: \($0.count)" })
// leftmost bit unanimous; the ancilla (parked at |−⟩) is a fair coin

// ------------------------------------------------------------
// §8 — Live view
// ------------------------------------------------------------
// q0's trajectory for f(x) = x, plus the shot histograms for a constant and a
// balanced oracle. Stateless views (no @State) — required for page code.

struct CountHistogram: View {
    let title: String
    let result: SimulationResult

    var body: some View {
        let sorted = result.sortedCounts
        let maxCount = max(sorted.map(\.count).max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) (\(result.shots) shots)")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(sorted, id: \.state) { entry in
                    VStack(spacing: 2) {
                        Text("\(entry.count)")
                            .font(.system(size: 8, design: .monospaced))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 80 * CGFloat(entry.count) / CGFloat(maxCount))
                        Text(entry.state)
                            .font(.system(size: 8, design: .monospaced))
                    }
                }
            }
            .frame(height: 110, alignment: .bottom)
        }
        .padding(8)
    }
}

struct DeutschView: View {
    let trajectory: [(String, BlochVector)]
    let constantResult: SimulationResult
    let balancedResult: SimulationResult

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(trajectory.indices, id: \.self) { i in
                    BlochSphereView(label: trajectory[i].0, bloch: trajectory[i].1, size: 150)
                }
            }
            HStack(alignment: .top, spacing: 24) {
                CountHistogram(title: "f(x) = 1 (constant)", result: constantResult)
                CountHistogram(title: "f(x) = x (balanced)", result: balancedResult)
            }
        }
        .padding()
    }
}

let startState = QuantumCircuit(qubits: 2).run()
PlaygroundPage.current.setLiveView(
    DeutschView(
        trajectory: [
            ("q0 start", BlochVector(startState, qubit: 0)),
            ("q0 after H", BlochVector(afterPrep, qubit: 0)),
            ("q0 after oracle", BlochVector(afterOracle, qubit: 0)),
            ("q0 after final H", BlochVector(afterFinalH, qubit: 0))
        ],
        constantResult: constResult,
        balancedResult: balResult
    )
    .frame(width: 720, height: 420)
)

//: [Next](@next)
