//: [Previous](@previous)
/*:
 # Entanglement: Bell and GHZ

 Entangled qubits have perfectly correlated outcomes, yet each qubit read alone still looks
 like a fair coin.

 - **Marginals can't tell** an entangled state from a product state — only the **joint** distribution can.
 - A Bell pair's reduced Bloch vectors collapse to the sphere's center (`|r| = 0`).
 - The four Bell states differ only by local `x`/`z` gates.
 - **No-signalling**: gates on q1 alone never change anything visible on q0.
 - The GHZ state extends the recipe to 3 qubits with a non-adjacent `cx(0, 2)`.

 Limit: `measure(shots:)` samples the whole register — there is no single-qubit or
 mid-circuit measurement.

 Follows Chapter 12 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func maxDiff(_ a: [Complex], _ b: [Complex]) -> Double {
    zip(a, b).map { ($0 - $1).magnitude }.max() ?? 0
}

func card(_ bloch: BlochVector) -> String {
    var text = String(format: "x %+.3f  y %+.3f  z %+.3f  θ %.3f rad",
                      bloch.x, bloch.y, bloch.z, bloch.theta)
    if abs(bloch.magnitude - 1) > 1e-3 { text += String(format: "  |r| %.3f", bloch.magnitude) }
    return text
}

func marginal(_ probs: [Double], qubits: Int, qubit: Int) -> [Double] {
    var result = [0.0, 0.0]
    for i in 0..<probs.count {
        let bit = (i >> (qubits - 1 - qubit)) & 1
        result[bit] += probs[i]
    }
    return result
}

// ------------------------------------------------------------
// §1 — Building the Bell state
// ------------------------------------------------------------

let hOnly = QuantumCircuit(qubits: 2)
hOnly.h(0)
print("h(0) only probabilities:", hOnly.run().probabilities)
// [0.5, 0, 0.5, 0]

let bell = QuantumCircuit(qubits: 2)
bell.h(0); bell.cx(0, 1)
let bellState = bell.run()
print("h(0); cx(0,1) probabilities:", bellState.probabilities)
// [0.5, 0, 0, 0.5]  (0.4999999999999999: ordinary floating-point residue)
print("amp |00⟩:", bellState[0], " amp |11⟩:", bellState[3])

// ------------------------------------------------------------
// §2 — Correlation, not local randomness
// ------------------------------------------------------------

let bellResult = bell.measure(shots: 1000)
print("Bell counts:", bellResult.sortedCounts.map { "|\($0.state)⟩: \($0.count)" })
// only 00 and 11

let plusPlus = QuantumCircuit(qubits: 2)
plusPlus.h(0); plusPlus.h(1)
let ppState = plusPlus.run()
let ppResult = plusPlus.measure(shots: 1000)
print("|++⟩ counts:", ppResult.sortedCounts.map { "|\($0.state)⟩: \($0.count)" })
// all four outcomes

print("Bell q0 marginal:", marginal(bellState.probabilities, qubits: 2, qubit: 0))
print("Bell q1 marginal:", marginal(bellState.probabilities, qubits: 2, qubit: 1))
print("|++⟩ q0 marginal:", marginal(ppState.probabilities, qubits: 2, qubit: 0))
// same 50/50 marginals — only the joint distribution differs

// ------------------------------------------------------------
// §3 — Reduced Bloch vectors
// ------------------------------------------------------------

for q in 0..<2 { print("Bell qubit \(q):", card(BlochVector(bellState, qubit: q))) }   // |r| 0
for q in 0..<2 { print("|++⟩ qubit \(q):", card(BlochVector(ppState, qubit: q))) }     // |r| 1

// ------------------------------------------------------------
// §4 — The four Bell states
// ------------------------------------------------------------

func describe(_ label: String, _ qc: QuantumCircuit) {
    let s = qc.run()
    print("\(label) probabilities:", s.probabilities)
}

let phiPlus = QuantumCircuit(qubits: 2); phiPlus.h(0); phiPlus.cx(0, 1)
let phiMinus = QuantumCircuit(qubits: 2); phiMinus.h(0); phiMinus.cx(0, 1); phiMinus.z(0)
let psiPlus = QuantumCircuit(qubits: 2); psiPlus.h(0); psiPlus.cx(0, 1); psiPlus.x(1)
let psiMinus = QuantumCircuit(qubits: 2)
psiMinus.h(0); psiMinus.cx(0, 1); psiMinus.x(1); psiMinus.z(0)

describe("Φ⁺", phiPlus)
describe("Φ⁻", phiMinus)
describe("Ψ⁺", psiPlus)
describe("Ψ⁻", psiMinus)

// Φ⁻ has the same probabilities as Φ⁺: the sign flip on |11⟩ is invisible to them.
print("|11⟩ amplitude Φ⁺:", phiPlus.run()[3], " Φ⁻:", phiMinus.run()[3])

// ------------------------------------------------------------
// §5 — Local gates can't create or destroy entanglement
// ------------------------------------------------------------

let gatesToTry: [(String, (QuantumCircuit) -> Void)] = [
    ("x", { $0.x(1) }), ("h", { $0.h(1) }), ("z", { $0.z(1) }), ("s", { $0.s(1) })
]
for (name, gate) in gatesToTry {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.cx(0, 1); gate(qc)
    let s = qc.run()
    print("after \(name)(1): q0", card(BlochVector(s, qubit: 0)),
          " marginal:", marginal(s.probabilities, qubits: 2, qubit: 0))
}
// q0 stays at |r| 0 with a 50/50 marginal every time

// Only the entangling gate itself undoes the entanglement.
let undo = QuantumCircuit(qubits: 2)
undo.h(0); undo.cx(0, 1); undo.cx(0, 1); undo.h(0)
print("h; cx; cx; h amplitudes:", undo.run().amplitudes)
// ≈ [1, 0, 0, 0]

// ------------------------------------------------------------
// §6 — The GHZ state
// ------------------------------------------------------------

let ghz = QuantumCircuit(qubits: 3)
ghz.h(0); ghz.cx(0, 1)
print("after h(0); cx(0,1):", ghz.run().probabilities)   // |000⟩ and |110⟩
ghz.cx(0, 2)                                              // non-adjacent: skips over q1
let ghzState = ghz.run()
print("after +cx(0,2):", ghzState.probabilities)         // |000⟩ and |111⟩

let ghzResult = ghz.measure(shots: 1000)
print("GHZ counts:", ghzResult.sortedCounts.map { "|\($0.state)⟩: \($0.count)" })
for q in 0..<3 { print("GHZ qubit \(q):", card(BlochVector(ghzState, qubit: q))) }

let ghzAlt = QuantumCircuit(qubits: 3)
ghzAlt.h(0); ghzAlt.cx(0, 1); ghzAlt.cx(1, 2)
print("cx(0,1);cx(1,2) vs cx(0,1);cx(0,2), max diff:",
      maxDiff(ghzAlt.run().amplitudes, ghzState.amplitudes))
// 0.0 — both wirings reach the same state

// apply(CNOTGate.matrix) is a fixed 4×4: a drop-in for cx(0, 1) on 2 qubits only.
// On a 3-qubit circuit it would trap.
let bellViaMatrix = QuantumCircuit(qubits: 2)
bellViaMatrix.h(0)
bellViaMatrix.apply(CNOTGate.matrix)
print("Bell via apply(CNOTGate.matrix):", bellViaMatrix.run().probabilities)

// ------------------------------------------------------------
// §7 — Live view
// ------------------------------------------------------------
// Bloch spheres for Bell and |++⟩, their count histograms, and the GHZ spheres.
// Stateless views (no @State) — required for page code.

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

struct EntanglementView: View {
    let bell: [BlochVector]
    let product: [BlochVector]
    let ghz: [BlochVector]
    let bellResult: SimulationResult
    let productResult: SimulationResult

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(bell.indices, id: \.self) { q in
                    BlochSphereView(label: "Bell q\(q)", bloch: bell[q], size: 130)
                }
                ForEach(product.indices, id: \.self) { q in
                    BlochSphereView(label: "|++⟩ q\(q)", bloch: product[q], size: 130)
                }
            }
            HStack(alignment: .top, spacing: 24) {
                CountHistogram(title: "Bell", result: bellResult)
                CountHistogram(title: "|++⟩", result: productResult)
            }
            HStack(spacing: 8) {
                ForEach(ghz.indices, id: \.self) { q in
                    BlochSphereView(label: "GHZ q\(q)", bloch: ghz[q], size: 130)
                }
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    EntanglementView(
        bell: (0..<2).map { BlochVector(bellState, qubit: $0) },
        product: (0..<2).map { BlochVector(ppState, qubit: $0) },
        ghz: (0..<3).map { BlochVector(ghzState, qubit: $0) },
        bellResult: bellResult,
        productResult: ppResult
    )
    .frame(width: 720, height: 640)
)

//: [Next](@next)
