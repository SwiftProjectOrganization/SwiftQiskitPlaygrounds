//: [Previous](@previous)
/*:
 # Grover's Search

 Among N = 2ⁿ items one is marked, and the only tool is an oracle that recognises it. Grover
 finds it in about (π/4)·√N queries, where a classical search needs about N/2.

 - CZ is built from `h(1); cx(0, 1); h(1)`.
 - A phase oracle for any marked state is CZ conjugated by `x` on the qubits whose bit is 0.
 - Diffusion `h; x; CZ; x; h` reflects every amplitude about the mean.
 - Unlike Chapters 13–14 the register **entangles** after the oracle (`|r| = 0`).
 - At N = 4 one iteration is exact; a second one over-rotates: P = sin²((2k+1)θ).
 - For 3 qubits, CCZ comes from `t`, `tdg` and `cx`; success is high but not certain.

 Limit: the oracle is a circuit you wrote, so "one query per iteration" describes the
 circuit's structure, not any enforced ignorance of what is inside it.

 Follows Chapter 15 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func card(_ bloch: BlochVector) -> String {
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", bloch.x, bloch.y, bloch.z, bloch.magnitude)
}

func bits(_ value: Int, width: Int) -> String {
    let s = String(value, radix: 2)
    return String(repeating: "0", count: max(0, width - s.count)) + s
}

// Nonzero real amplitudes as "|ab⟩: +0.5000" strings.
func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { "|\(bits($0, width: qubits))⟩: \(String(format: "%+.4f", state[$0].real))" }
        .joined(separator: "   ")
}

// ------------------------------------------------------------
// §1 — CZ from H and CX
// ------------------------------------------------------------

func cz(_ qc: QuantumCircuit) { qc.h(1); qc.cx(0, 1); qc.h(1) }

let czCheck = QuantumCircuit(qubits: 2)
czCheck.h(0); czCheck.h(1)
cz(czCheck)
print("CZ on |s>:", pretty(czCheck.run(), qubits: 2))
// only |11⟩ flips sign

// ------------------------------------------------------------
// §2 — Phase oracles via X-conjugation
// ------------------------------------------------------------

func phaseOracle(marked: Int) -> (QuantumCircuit) -> Void {
    { qc in
        let zeroBits = (0..<2).filter { (marked >> (1 - $0)) & 1 == 0 }
        for q in zeroBits { qc.x(q) }
        cz(qc)
        for q in zeroBits { qc.x(q) }
    }
}

print("\noracle on |s>:")
for marked in 0..<4 {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.h(1)
    phaseOracle(marked: marked)(qc)
    print(" U_|\(bits(marked, width: 2))>:", pretty(qc.run(), qubits: 2))
}
// the marked amplitude is −0.5; all probabilities stay 0.25

// ------------------------------------------------------------
// §3 — The same oracle as a bit oracle on a |−⟩ ancilla
// ------------------------------------------------------------

var bitOracle = Matrix.identity(size: 8)
for basis in 0..<8 {
    let q0 = (basis >> 2) & 1, q1 = (basis >> 1) & 1
    if q0 == 1 && q1 == 0 {
        bitOracle[basis, basis] = Complex.zero
        bitOracle[basis ^ 1, basis] = Complex(1)
    }
}
let ancillaQC = QuantumCircuit(qubits: 3)
ancillaQC.x(2)
ancillaQC.h(0); ancillaQC.h(1); ancillaQC.h(2)
ancillaQC.apply(bitOracle)
print("\nbit oracle on |-> ancilla:", pretty(ancillaQC.run(), qubits: 3))
// the leading-two-bit signs +, +, −, + match the direct phase oracle for |10⟩

// ------------------------------------------------------------
// §4 — Diffusion, stage by stage (marked |10⟩)
// ------------------------------------------------------------

func diffusion(_ qc: QuantumCircuit) {
    qc.h(0); qc.h(1); qc.x(0); qc.x(1); cz(qc); qc.x(0); qc.x(1); qc.h(0); qc.h(1)
}

let walk = QuantumCircuit(qubits: 2)
walk.h(0); walk.h(1)
print("\nuniform |s>:    ", pretty(walk.run(), qubits: 2))
walk.x(1); cz(walk); walk.x(1)
let afterOracle = walk.run()
print("after oracle:   ", pretty(afterOracle, qubits: 2))
var sum = Complex.zero
for i in 0..<afterOracle.dimension { sum = sum + afterOracle[i] }
print("amplitude mean: ", sum * Complex(0.25))    // 0.25
diffusion(walk)
print("after diffusion:", pretty(walk.run(), qubits: 2))
// |10⟩ with amplitude −1: the gate construction equals −D, a global phase

// ------------------------------------------------------------
// §5 — The register entangles mid-circuit
// ------------------------------------------------------------

let ent = QuantumCircuit(qubits: 2)
func show(_ label: String) {
    let s = ent.run()
    print(label, "q0", card(BlochVector(s, qubit: 0)), " q1", card(BlochVector(s, qubit: 1)))
}
print()
ent.h(0); ent.h(1);                    show("after H,H:      ")
ent.x(1); cz(ent); ent.x(1);           show("after oracle:   ")
ent.h(0); ent.h(1);                    show("diffusion H,H:  ")
ent.x(0); ent.x(1);                    show("diffusion X,X:  ")
cz(ent);                               show("diffusion CZ:   ")
ent.x(0); ent.x(1);                    show("diffusion X,X:  ")
ent.h(0); ent.h(1);                    show("final:          ")
// |r| drops to 0 at the oracle's CZ and returns to 1 only at diffusion's CZ

// ------------------------------------------------------------
// §6 — Exact success at N = 4
// ------------------------------------------------------------

func groverCircuit(marked: Int, iterations: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 2)
    qc.h(0); qc.h(1)
    for _ in 0..<iterations { phaseOracle(marked: marked)(qc); diffusion(qc) }
    return qc
}

print("\nmarked   P(marked)")
for marked in 0..<4 {
    let p = groverCircuit(marked: marked, iterations: 1).run().probabilities[marked]
    print(" |\(bits(marked, width: 2))>    \(String(format: "%.4f", p))")
}
let shots2 = groverCircuit(marked: 2, iterations: 1).measure(shots: 1000)
print("marked |10>, 1000 shots:", shots2.sortedCounts.map { "\($0.state): \($0.count)" })
// every shot reads 10 — no ancilla coin to slice off

// ------------------------------------------------------------
// §7 — Over-rotation
// ------------------------------------------------------------

let theta = asin(1.0 / 2.0)
print("\nk   P(simulated)  P(sin²((2k+1)θ))")
for k in 0...4 {
    let pSim = groverCircuit(marked: 2, iterations: k).run().probabilities[2]
    let pFormula = pow(sin(Double(2 * k + 1) * theta), 2)
    print(" \(k)   \(String(format: "%.4f", pSim))        \(String(format: "%.4f", pFormula))")
}
// 0.25, 1, 0.25, 0.25, 1 — more queries is not automatically better

// ------------------------------------------------------------
// §8 — The Dirac view: D = 2|s⟩⟨s| − I
// ------------------------------------------------------------

let sPrep = QuantumCircuit(qubits: 2)
sPrep.h(0); sPrep.h(1)
let s = sPrep.run()
let projector = s * s†
var d = Matrix(rows: 4, cols: 4)
for i in 0..<4 {
    for j in 0..<4 {
        d[i, j] = Complex(2) * projector[i, j] - (i == j ? Complex(1) : Complex.zero)
    }
}
let viaDirac = QuantumCircuit(qubits: 2)
viaDirac.h(0); viaDirac.h(1)
viaDirac.x(1); cz(viaDirac); viaDirac.x(1)
viaDirac.apply(d)
print("\nvia 2|s><s| - I:   ", pretty(viaDirac.run(), qubits: 2))
print("via gate diffusion:", pretty(groverCircuit(marked: 2, iterations: 1).run(), qubits: 2))
// same state up to the global sign

// ------------------------------------------------------------
// §9 — Three qubits: CCZ from T, T† and CX
// ------------------------------------------------------------

func ccz(_ qc: QuantumCircuit, _ a: Int, _ b: Int, _ c: Int) {
    qc.cx(b, c); qc.tdg(c); qc.cx(a, c); qc.t(c); qc.cx(b, c); qc.tdg(c); qc.cx(a, c)
    qc.t(b); qc.t(c); qc.cx(a, b); qc.t(a); qc.tdg(b); qc.cx(a, b)
}

var cczMatrix = Matrix.identity(size: 8)
cczMatrix[7, 7] = Complex(-1)

print("\nbasis  gates-CCZ  matrix-CCZ  match")
for basis in 0..<8 {
    let gateQC = QuantumCircuit(qubits: 3)
    let matrixQC = QuantumCircuit(qubits: 3)
    for q in 0..<3 where (basis >> (2 - q)) & 1 == 1 { gateQC.x(q); matrixQC.x(q) }
    ccz(gateQC, 0, 1, 2)
    matrixQC.apply(cczMatrix)
    let g = gateQC.run()[basis].real, m = matrixQC.run()[basis].real
    print(" \(basis)     \(String(format: "%+.1f", g))       \(String(format: "%+.1f", m))       \(abs(g - m) < 1e-9)")
}

func oracle3(_ qc: QuantumCircuit, marked: Int) {
    let zeroBits = (0..<3).filter { (marked >> (2 - $0)) & 1 == 0 }
    for q in zeroBits { qc.x(q) }
    ccz(qc, 0, 1, 2)
    for q in zeroBits { qc.x(q) }
}

func diffusion3(_ qc: QuantumCircuit) {
    for q in 0..<3 { qc.h(q) }
    for q in 0..<3 { qc.x(q) }
    ccz(qc, 0, 1, 2)
    for q in 0..<3 { qc.x(q) }
    for q in 0..<3 { qc.h(q) }
}

func grover3(marked: Int, iterations: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 3)
    for q in 0..<3 { qc.h(q) }
    for _ in 0..<iterations { oracle3(qc, marked: marked); diffusion3(qc) }
    return qc
}

print("\nk (iterations)  P(marked |101>)")
var curve: [Double] = []
for k in 0...5 {
    let p = grover3(marked: 5, iterations: k).run().probabilities[5]
    curve.append(p)
    print("  \(k)              \(String(format: "%.4f", p))")
}
// peaks near k = 2 (0.9453), then rotates past the target

let shots3 = grover3(marked: 5, iterations: 2).measure(shots: 1000)
print("\n1000 shots at k = 2:", shots3.sortedCounts.map { "\($0.state): \($0.count)" })
// 101 dominates at about 95%

// ------------------------------------------------------------
// §10 — The query-count gap
// ------------------------------------------------------------

print("\nn   N     optimal k   quantum ≈ k·√N   classical avg   classical worst")
for n in 2...8 {
    let N = 1 << n
    let th = asin(1.0 / Double(N).squareRoot())
    let k = Int((Double.pi / (4 * th) - 0.5).rounded())
    print("\(n)   \(N)   \(k)   \(String(format: "%.1f", Double(k) * Double(N).squareRoot()))   \(N / 2)   \(N - 1)")
}
// quadratic, not exponential; √N is optimal for unstructured search

// ------------------------------------------------------------
// §11 — Live view
// ------------------------------------------------------------
// P(marked |101⟩) per iteration for 3 qubits, and the shot histogram at k = 2.
// Stateless views (no @State) — required for page code.

struct CurveView: View {
    let values: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("P(marked |101⟩) vs iterations k")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(values.indices, id: \.self) { k in
                    VStack(spacing: 2) {
                        Text(String(format: "%.3f", values[k]))
                            .font(.system(size: 9, design: .monospaced))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: 36, height: 100 * CGFloat(values[k]))
                        Text("k = \(k)")
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
        .padding(8)
    }
}

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

struct GroverView: View {
    let curve: [Double]
    let shots: SimulationResult

    var body: some View {
        VStack(spacing: 16) {
            CurveView(values: curve)
            CountHistogram(title: "3 qubits, k = 2", result: shots)
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    GroverView(curve: curve, shots: shots3)
        .frame(width: 520, height: 400)
)

//: [Next](@next)
