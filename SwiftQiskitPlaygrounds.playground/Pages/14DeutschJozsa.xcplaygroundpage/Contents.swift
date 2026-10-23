//: [Previous](@previous)
/*:
 # Deutsch–Jozsa and Bernstein–Vazirani

 Chapter 13's one-query trick, widened from one bit to n: Deutsch–Jozsa decides constant vs.
 balanced for an n-bit function in a single query, and Bernstein–Vazirani reuses the identical
 circuit to read back a whole hidden n-bit string in that same query.

 - Qubits 0…n−1 are the inputs (qubit 0 is the leftmost bit); the ancilla is qubit n.
 - Circuit: `x(ancilla)`, `H` on everything, oracle, then `H` on the **inputs only**.
 - Every oracle is `f(x) = s·x mod 2`, built from `cx(q, ancilla)` for each set bit of s.
 - The verdict is the marginal P(inputs = 000), summed over the ancilla.
 - The ancilla ends in `|−⟩`, so its bit in a shot is a free coin.
 - A non-linear oracle still gives a correct DJ verdict, but destroys the BV readout.

 Limit: `measure(shots:)` samples the whole register, so slice off the last character
 (the ancilla) before reading a verdict.

 Follows Chapter 14 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

let n = 3
let ancilla = n
let total = n + 1

func card(_ bloch: BlochVector) -> String {
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", bloch.x, bloch.y, bloch.z, bloch.magnitude)
}

func bits(_ value: Int, width: Int) -> String {
    let s = String(value, radix: 2)
    return String(repeating: "0", count: max(0, width - s.count)) + s
}

// Marginal over the n input qubits (the ancilla is the last bit of the index).
func inputMarginal(_ qc: QuantumCircuit) -> [Double] {
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in qc.run().probabilities.enumerated() { marginal[i >> 1] += p }
    return marginal
}

// ------------------------------------------------------------
// §1 — The circuit, widened
// ------------------------------------------------------------

func djCircuit(oracle: (QuantumCircuit) -> Void) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: total)
    qc.x(ancilla)
    for q in 0...ancilla { qc.h(q) }
    oracle(qc)
    for q in 0..<n { qc.h(q) }    // inputs only — NOT the ancilla
    return qc
}

// ------------------------------------------------------------
// §2 — Oracles from cx
// ------------------------------------------------------------

struct Oracle {
    let name: String
    let isBalanced: Bool
    let apply: (QuantumCircuit) -> Void
}

let oracles: [Oracle] = [
    Oracle(name: "constant 0     ", isBalanced: false) { _ in },
    Oracle(name: "constant 1     ", isBalanced: false) { $0.x(ancilla) },
    Oracle(name: "balanced on x0 ", isBalanced: true) { $0.cx(0, ancilla) },
    Oracle(name: "balanced parity", isBalanced: true) { qc in
        for q in 0..<n { qc.cx(q, ancilla) }
    }
]

// ------------------------------------------------------------
// §3 — The verdict
// ------------------------------------------------------------

print("oracle           P(|000⟩)  verdict    expected")
for oracle in oracles {
    let allZero = inputMarginal(djCircuit(oracle: oracle.apply))[0]
    let verdict = allZero > 0.5 ? "constant" : "balanced"
    let expected = oracle.isBalanced ? "balanced" : "constant"
    print("\(oracle.name)  \(String(format: "%.4f", allZero))    \(verdict)   \(expected)")
}
// Exactly 1 or exactly 0, for every n — one query.

// ------------------------------------------------------------
// §4 — Shot statistics, and a gotcha
// ------------------------------------------------------------

let balancedShots = djCircuit(oracle: { $0.cx(0, ancilla) }).measure(shots: 200)
print("\nbalanced-on-x0, 200 shots, raw outcome strings:")
for (outcome, count) in balancedShots.sortedCounts {
    print("  \(outcome): \(count)")
}
// 1000 and 1001, near 50/50: input prefix 100 is fixed, the ancilla bit is a coin.

let qcExtra = QuantumCircuit(qubits: total)
qcExtra.x(ancilla)
for q in 0...ancilla { qcExtra.h(q) }
qcExtra.cx(0, ancilla)
for q in 0...ancilla { qcExtra.h(q) }    // the slip: H on the ancilla too
print("\nextra H on ancilla too, nonzero probs:")
for (i, p) in qcExtra.run().probabilities.enumerated() where p > 1e-9 {
    print("  \(bits(i, width: total)): \(String(format: "%.4f", p))")
}
// 1001: 1.0000 — the ancilla is pinned to 1; the inputs are undisturbed.

// ------------------------------------------------------------
// §5 — Bernstein–Vazirani: reading back a hidden string
// ------------------------------------------------------------

func bvOracle(_ s: Int) -> (QuantumCircuit) -> Void {
    { qc in
        for q in 0..<n where (s >> (n - 1 - q)) & 1 == 1 {
            qc.cx(q, ancilla)
        }
    }
}

let hiddenS = 0b101
let bv = QuantumCircuit(qubits: total)
bv.x(ancilla)
for q in 0...ancilla { bv.h(q) }
bvOracle(hiddenS)(bv)
let bvAfterOracle = bv.run()
print("\nafter oracle, s = 101:")
for q in 0..<total { print("  q\(q):", card(BlochVector(bvAfterOracle, qubit: q))) }
for q in 0..<n { bv.h(q) }
let bvFinal = bv.run()
print("final cards:")
for q in 0..<total { print("  q\(q):", card(BlochVector(bvFinal, qubit: q))) }
// Bits of s read z = −1 (1) or +1 (0) on the inputs; the ancilla stays at x = −1.

print("\nhidden s   recovered   P")
for hidden in [0b101, 0b110, 0b111, 0b000] {
    let marginal = inputMarginal(djCircuit(oracle: bvOracle(hidden)))
    if let top = marginal.enumerated().max(by: { $0.element < $1.element }) {
        print("\(bits(hidden, width: n))        \(bits(top.offset, width: n))         \(String(format: "%.4f", top.element))")
    }
}

// ------------------------------------------------------------
// §6 — A non-linear oracle: f(x) = (x0 AND x1) XOR x2
// ------------------------------------------------------------
// Not expressible with cx alone, so it is a hand-built permutation matrix applied
// with QuantumCircuit.apply(_:).

var permutation = Matrix(rows: 1 << total, cols: 1 << total)
for basis in 0..<(1 << total) {
    let x0 = (basis >> 3) & 1, x1 = (basis >> 2) & 1, x2 = (basis >> 1) & 1
    let f = (x0 & x1) ^ x2
    permutation[f == 1 ? (basis ^ 1) : basis, basis] = Complex(1, 0)
}

let nonLinear = QuantumCircuit(qubits: total)
nonLinear.x(ancilla)
for q in 0...ancilla { nonLinear.h(q) }
nonLinear.apply(permutation)
let nlAfterOracle = nonLinear.run()
print("\nnon-linear oracle, cards after the oracle:")
for q in 0..<total { print("  q\(q):", card(BlochVector(nlAfterOracle, qubit: q))) }
// q0 and q1 have |r| 0: the AND term entangles them.

for q in 0..<n { nonLinear.h(q) }
print("P(|000⟩) =", String(format: "%.4f", inputMarginal(nonLinear)[0]))
print("nonzero final outcomes:")
for (i, p) in nonLinear.run().probabilities.enumerated() where p > 1e-9 {
    print("  \(bits(i, width: total)): \(String(format: "%.4f", p))")
}
// P(|000⟩) = 0 → DJ still says balanced; BV's readout spreads over 8 strings.

// ------------------------------------------------------------
// §7 — The query-count gap
// ------------------------------------------------------------

print("\nn    quantum queries   classical DJ (worst case)   classical BV")
for width in 2...5 {
    print("\(width)    1                 \((1 << (width - 1)) + 1)                          \(width)")
}
// Arithmetic, not a run: 2^(n−1)+1 for certain DJ, exactly n for BV.

// ------------------------------------------------------------
// §8 — Live view
// ------------------------------------------------------------
// Bloch cards for the BV run (s = 101) after the oracle and after the closing H,
// plus the shot histogram. Stateless views (no @State) — required for page code.

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

struct DeutschJozsaView: View {
    let afterOracle: StateVector
    let final: StateVector
    let shots: SimulationResult

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { q in
                    BlochSphereView(label: "q\(q) after oracle", bloch: BlochVector(afterOracle, qubit: q), size: 130)
                }
            }
            HStack(spacing: 8) {
                ForEach(0..<total, id: \.self) { q in
                    BlochSphereView(label: "q\(q) final", bloch: BlochVector(final, qubit: q), size: 130)
                }
            }
            CountHistogram(title: "BV s = 101", result: shots)
        }
        .padding()
    }
}

let bvShots = djCircuit(oracle: bvOracle(hiddenS)).measure(shots: 1000)
PlaygroundPage.current.setLiveView(
    DeutschJozsaView(afterOracle: bvAfterOracle, final: bvFinal, shots: bvShots)
        .frame(width: 600, height: 520)
)

//: [Next](@next)
