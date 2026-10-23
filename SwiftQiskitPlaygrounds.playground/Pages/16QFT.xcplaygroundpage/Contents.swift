//: [Previous](@previous)
/*:
 # The Quantum Fourier Transform and Phase Estimation

 The QFT maps a basis state `|c⟩` to `(1/√N) Σ e^(2πi·y·c/N) |y⟩`: the index moves into the
 phases. Run backwards, it reads a phase back out as a number.

 - There is no native controlled-phase gate; `CP(θ)` is `p; cx; p; cx; p`.
 - `CP(π/2)` and `CP(π)` are exactly `t`/`tdg` and `s`/`sdg` plus `cx`.
 - The ladder (`h` then `CP` from every later qubit) ends in a swap network.
 - The QFT of a basis state is a **product state**: every qubit stays pure (`|r| = 1`).
 - The inverse QFT reverses the gates and negates the angles; QFT·QFT† = I.
 - Phase estimation: controlled powers of `P(2πφ)` on a `|1⟩` eigenstate, then the inverse QFT.
 - More counting qubits give a finer grid, so the error shrinks and the peak sharpens.

 Limit: `measure(shots:)` samples the whole register, so the counting register is read
 off the leading bits and the eigenstate qubit is the last bit.

 Follows Chapter 16 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func card(_ bloch: BlochVector) -> String {
    String(format: "x %+.3f  y %+.3f  z %+.3f  |r| %.3f", bloch.x, bloch.y, bloch.z, bloch.magnitude)
}

func fmt(_ d: Double) -> String { String(format: "%.4f", d) }

func fmtAmp(_ c: Complex) -> String {
    let re = c.real.magnitude < 1e-9 ? 0 : c.real
    let im = c.imag.magnitude < 1e-9 ? 0 : c.imag
    if im == 0 { return String(format: "%+.4f", re) }
    if re == 0 { return String(format: "%+.4fi", im) }
    return String(format: "%+.4f%+.4fi", re, im)
}

// ------------------------------------------------------------
// §1 — The controlled-phase gate CP(θ)
// ------------------------------------------------------------

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control)
    qc.cx(control, target)
    qc.p(-theta / 2, target)
    qc.cx(control, target)
    qc.p(theta / 2, target)
}
func cpHalfPi(_ qc: QuantumCircuit, _ c: Int, _ t: Int) { qc.t(c); qc.cx(c, t); qc.tdg(t); qc.cx(c, t); qc.t(t) }
func cpPi(_ qc: QuantumCircuit, _ c: Int, _ t: Int) { qc.s(c); qc.cx(c, t); qc.sdg(t); qc.cx(c, t); qc.s(t) }
func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) { qc.cx(a, b); qc.cx(b, a); qc.cx(a, b) }

print("input  CP(π/2) via p()  CP(π/2) via T/T†  CP(π) via S/S†")
for c in 0..<4 {
    func prepared(_ gate: (QuantumCircuit) -> Void) -> Complex {
        let qc = QuantumCircuit(qubits: 2)
        if c & 2 != 0 { qc.x(0) }
        if c & 1 != 0 { qc.x(1) }
        gate(qc)
        return qc.run()[c]
    }
    let a = prepared { cp($0, .pi / 2, 0, 1) }
    let b = prepared { cpHalfPi($0, 0, 1) }
    let d = prepared { cpPi($0, 0, 1) }
    print(" |\(c >> 1)\(c & 1)⟩   ", fmtAmp(a), "   ", fmtAmp(b), "   ", fmtAmp(d))
}
// only |11⟩ picks up a phase: +i for π/2, −1 for π

let sPrep = QuantumCircuit(qubits: 2)
sPrep.h(0); sPrep.h(1); cpPi(sPrep, 0, 1)
print("\nCP(π) on |s>:", (0..<4).map { fmtAmp(sPrep.run()[$0]) }.joined(separator: "   "))
// CP(π) is CZ — the same output as Chapter 15's CZ

// ------------------------------------------------------------
// §2 — The QFT ladder, checked against the DFT formula
// ------------------------------------------------------------

func appendQFT(_ qc: QuantumCircuit, qubits n: Int, swaps: Bool = true) {
    for j in 0..<n {
        qc.h(j)
        for k in (j + 1)..<n {
            cp(qc, 2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j)
        }
    }
    if swaps { for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) } }
}

func basisPrep(_ qc: QuantumCircuit, _ c: Int, qubits n: Int) {
    for q in 0..<n where (c >> (n - 1 - q)) & 1 == 1 { qc.x(q) }
}

let n = 3, N = 8
var maxDeviation = 0.0
for c in 0..<N {
    let qc = QuantumCircuit(qubits: n)
    basisPrep(qc, c, qubits: n)
    appendQFT(qc, qubits: n)
    let amps = qc.run().amplitudes
    for y in 0..<N {
        let theta = 2 * Double.pi * Double(y * c) / Double(N)
        let want = Complex(cos(theta), sin(theta)) * (1.0 / sqrt(Double(N)))
        maxDeviation = max(maxDeviation, (amps[y] - want).magnitude)
    }
}
print("\ngate-level QFT vs. DFT formula, max deviation:", maxDeviation)
// ~1e-15

// ------------------------------------------------------------
// §3 — Why the ladder ends in swaps
// ------------------------------------------------------------

func bitReverse(_ y: Int, bits: Int) -> Int {
    var r = 0
    for i in 0..<bits where (y >> i) & 1 == 1 { r |= 1 << (bits - 1 - i) }
    return r
}

let withSwapsQC = QuantumCircuit(qubits: n)
basisPrep(withSwapsQC, 3, qubits: n)
appendQFT(withSwapsQC, qubits: n)
let withSwaps = withSwapsQC.run().amplitudes
let withoutSwapsQC = QuantumCircuit(qubits: n)
basisPrep(withoutSwapsQC, 3, qubits: n)
appendQFT(withoutSwapsQC, qubits: n, swaps: false)
let withoutSwaps = withoutSwapsQC.run().amplitudes
var reorderDeviation = 0.0
for y in 0..<N {
    reorderDeviation = max(reorderDeviation, (withSwaps[y] - withoutSwaps[bitReverse(y, bits: n)]).magnitude)
}
print("no-swap amplitudes sit at bit-reverse(y), max deviation:", reorderDeviation)
// 0.0 — an exact reordering, not an approximation

// ------------------------------------------------------------
// §4 — The QFT of a basis state is a product state
// ------------------------------------------------------------

print()
var qft5State = StateVector(qubits: n)
for c in [0, 3, 5] {
    let qc = QuantumCircuit(qubits: n)
    basisPrep(qc, c, qubits: n)
    appendQFT(qc, qubits: n)
    let state = qc.run()
    if c == 5 { qft5State = state }
    print("QFT|\(c)⟩:", (0..<n).map { "q\($0) " + card(BlochVector(state, qubit: $0)) }.joined(separator: "   "))
}
// |r| = 1 on every qubit: each sits on the equator at a phase set by its bit of c

// ------------------------------------------------------------
// §5 — The inverse QFT, and unitarity
// ------------------------------------------------------------

func appendInverseQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    for j in stride(from: n - 1, through: 0, by: -1) {
        for k in stride(from: n - 1, through: j + 1, by: -1) {
            cp(qc, -2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j)
        }
        qc.h(j)
    }
}

var unitarityDeviation = 0.0
for c in 0..<N {
    let qc = QuantumCircuit(qubits: n)
    basisPrep(qc, c, qubits: n)
    appendQFT(qc, qubits: n)
    appendInverseQFT(qc, qubits: n)
    unitarityDeviation = max(unitarityDeviation, (qc.run()[c].magnitude - 1.0).magnitude)
}
print("\nQFT then QFT†, max |amplitude at c| deviation from 1:", unitarityDeviation)

// ------------------------------------------------------------
// §6 — Phase estimation
// ------------------------------------------------------------
// The eigenstate qubit is last (the least-significant bit of the index).

func phaseEstimation(counting n: Int, phase: Double) -> [Double] {
    let qc = QuantumCircuit(qubits: n + 1)
    qc.x(n)                                   // |1⟩ is an eigenstate of P(2πφ)
    for q in 0..<n { qc.h(q) }
    for j in 0..<n {
        let power = 1 << (n - 1 - j)
        cp(qc, 2 * Double.pi * phase * Double(power), j, n)
    }
    appendInverseQFT(qc, qubits: n)
    var marginal = [Double](repeating: 0, count: 1 << n)
    for (i, p) in qc.run().probabilities.enumerated() { marginal[i >> 1] += p }
    return marginal
}

print("\nphase   best estimate   P")
for phase in [0.125, 0.5, 0.75] {
    let marginal = phaseEstimation(counting: 3, phase: phase)
    if let top = marginal.enumerated().max(by: { $0.element < $1.element }) {
        print(fmt(phase), "  ", fmt(Double(top.offset) / 8.0), "         ", fmt(top.element))
    }
}
// dyadic phases come back with certainty

let spread = phaseEstimation(counting: 3, phase: 0.3)
print("\nφ = 0.3, 3 counting qubits:")
for (y, p) in spread.enumerated() where p > 0.01 {
    print("  y=\(y) (estimate \(fmt(Double(y) / 8.0))): P = \(fmt(p))")
}
// y = 2 and 3, the grid points flanking 0.3, carry about 0.84

let shotQC = QuantumCircuit(qubits: 3)
shotQC.x(2)
shotQC.h(0); shotQC.h(1)
cp(shotQC, 2 * Double.pi * 0.25 * 2, 0, 2)
cp(shotQC, 2 * Double.pi * 0.25 * 1, 1, 2)
appendInverseQFT(shotQC, qubits: 2)
let shotResult = shotQC.measure(shots: 1000)
print("\nφ = 0.25, 2 counting qubits, 1000 shots:", shotResult.sortedCounts.map { "\($0.state): \($0.count)" })
// 011: 1000 — counting 01 = 0.25, eigenstate 1

// ------------------------------------------------------------
// §7 — Precision scales with counting qubits
// ------------------------------------------------------------

print("\ncounting qubits   best estimate   error    P")
for counting in [3, 6] {
    let marginal = phaseEstimation(counting: counting, phase: 0.3)
    if let top = marginal.enumerated().max(by: { $0.element < $1.element }) {
        let estimate = Double(top.offset) / Double(1 << counting)
        print(counting, "                ", fmt(estimate), "         ", fmt(abs(estimate - 0.3)), "  ", fmt(top.element))
    }
}
// 3: 0.2500, error 0.0500;  6: 0.2969, error 0.0031

// ------------------------------------------------------------
// §8 — Live view
// ------------------------------------------------------------
// QFT|5⟩ as three equator Bloch spheres, and the φ = 0.3 estimate distribution.
// Stateless views (no @State) — required for page code.

struct EstimateBars: View {
    let title: String
    let values: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(values.indices, id: \.self) { y in
                    VStack(spacing: 2) {
                        Text(String(format: "%.3f", values[y]))
                            .font(.system(size: 9, design: .monospaced))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: 32, height: max(1, 100 * CGFloat(values[y])))
                        Text("y=\(y)")
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
        .padding(8)
    }
}

struct QFTView: View {
    let qft: StateVector
    let estimate: [Double]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<n, id: \.self) { q in
                    BlochSphereView(label: "QFT|5⟩ q\(q)", bloch: BlochVector(qft, qubit: q), size: 160)
                }
            }
            EstimateBars(title: "Phase estimation, φ = 0.3, 3 counting qubits", values: estimate)
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    QFTView(qft: qft5State, estimate: spread)
        .frame(width: 620, height: 420)
)

//: [Next](@next)
