//: [Previous](@previous)
/*:
 # Discrete-Time Quantum Walks

 The quantum analogue of a random walk: probability *spreads* by interference rather than by
 chance. A coin qubit picks a direction; a position register says where the walker is.

 - 16 sites on a cycle (a 4-qubit position register) plus one coin qubit, so the dimension
   is 32 and a basis state's index is `coin·16 + pos`.
 - One step is a Hadamard coin `H ⊗ I₁₆`, then a conditional shift built as a permutation
   `Matrix` and applied with `apply(_:)`.
 - Quantum spread σ grows linearly in t (ballistic); the classical walk grows as √t.
 - On a cycle, σ must be computed from **signed offsets**, or sites near the 0/15 wraparound
   give nonsense.
 - A `|0⟩` coin gives a lopsided distribution; a `|+i⟩` coin restores exact symmetry.
 - On a 4-site cycle the shift is exactly three gates, `cx(0,1); cx(2,1); x(2)`.

 Limit: 16 sites stay free of wraparound aliasing only through t = 7.

 Follows Chapter 25 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

let numSites = 16
let dim = 32

// ------------------------------------------------------------
// §1 — The shift operator as a hand-built permutation
// ------------------------------------------------------------

func buildShift() -> Matrix {
    var m = Matrix(rows: dim, cols: dim)
    for coin in 0...1 {
        for pos in 0..<numSites {
            let newPos = coin == 0 ? (pos + 1) % numSites : (pos - 1 + numSites) % numSites
            m[coin * numSites + newPos, coin * numSites + pos] = .one
        }
    }
    return m
}

let shift = buildShift()
let identity16 = Matrix.identity(size: numSites)
let stepOperator = shift * HadamardGate.matrix.tensor(identity16)

func initialState(coin: Ket) -> Ket {
    var posAmp = Array(repeating: Complex.zero, count: numSites)
    posAmp[0] = .one
    return coin.tensor(StateVector(posAmp))
}

// The position marginal sums out the coin.
func positionDistribution(_ psi: Ket) -> [Double] {
    var dist = Array(repeating: 0.0, count: numSites)
    for coin in 0...1 {
        for pos in 0..<numSites { dist[pos] += psi[coin * numSites + pos].magnitudeSquared }
    }
    return dist
}

func quantumDistribution(coin: Ket, steps: Int) -> [Double] {
    var psi = initialState(coin: coin)
    for _ in 0..<steps { psi.apply(stepOperator) }
    return positionDistribution(psi)
}

func classicalDistribution(steps: Int) -> [Double] {
    var dist = Array(repeating: 0.0, count: numSites)
    dist[0] = 1.0
    for _ in 0..<steps {
        var next = Array(repeating: 0.0, count: numSites)
        for (pos, p) in dist.enumerated() {
            next[(pos + 1) % numSites] += 0.5 * p
            next[(pos - 1 + numSites) % numSites] += 0.5 * p
        }
        dist = next
    }
    return dist
}

var maxAbs = 0.0
let StS = (shift†) * shift
for i in 0..<dim {
    for j in 0..<dim {
        let expected: Complex = (i == j) ? .one : .zero
        maxAbs = max(maxAbs, (StS[i, j] - expected).magnitude)
    }
}
print("S†S = I max diff: \(String(format: "%.2e", maxAbs))")
// exactly 0: a permutation matrix is unitary by construction

// ------------------------------------------------------------
// §2 — Ballistic vs. diffusive spreading
// ------------------------------------------------------------

// Unwrap each site to a signed offset from the start, or σ breaks near the wraparound.
func signedOffset(_ pos: Int) -> Int { pos <= numSites / 2 ? pos : pos - numSites }

func stddev(_ distribution: [Double]) -> Double {
    var mean = 0.0
    for (pos, p) in distribution.enumerated() { mean += Double(signedOffset(pos)) * p }
    var variance = 0.0
    for (pos, p) in distribution.enumerated() { variance += p * pow(Double(signedOffset(pos)) - mean, 2) }
    return variance.squareRoot()
}

print("\nt   quantum σ   σ/t")
for t in 1...7 {
    let sigma = stddev(quantumDistribution(coin: .zero, steps: t))
    print("\(t)   \(String(format: "%.4f", sigma))      \(String(format: "%.4f", sigma / Double(t)))")
}
print("\nt   classical σ   σ/√t")
for t in 1...7 {
    let sigma = stddev(classicalDistribution(steps: t))
    print("\(t)   \(String(format: "%.4f", sigma))       \(String(format: "%.4f", sigma / Double(t).squareRoot()))")
}
// classical σ/√t is pinned at 1.0; quantum σ/t hovers near 0.5 instead of shrinking

// ------------------------------------------------------------
// §3 — Why |0⟩ is lopsided and |+i⟩ is symmetric
// ------------------------------------------------------------

let biased = quantumDistribution(coin: .zero, steps: 7)
let symmetric = quantumDistribution(coin: .plusI, steps: 7)
print("\nsite   P(biased, coin=|0⟩)   P(symmetric, coin=|+i⟩)")
for site in [1, 3, 5, 7, 9, 11, 13, 15] {
    print("\(site)      \(String(format: "%.4f", biased[site]))                 \(String(format: "%.4f", symmetric[site]))")
}
// the |+i⟩ column is mirror-symmetric: 1↔15, 3↔13, 5↔11, 7↔9

// ------------------------------------------------------------
// §4 — A 4-site walk from three gates
// ------------------------------------------------------------
// With 2 position qubits the carry stays linear, so the shift is cx(0,1); cx(2,1); x(2).
// Coin is q0, position is q1 (MSB) and q2 (LSB).

func gateWalk(prepareCoin: Bool, steps: Int) -> [Double] {
    let qc = QuantumCircuit(qubits: 3)
    if prepareCoin { qc.h(0); qc.s(0) }    // |+i⟩
    for _ in 0..<steps {
        qc.h(0)
        qc.cx(0, 1); qc.cx(2, 1); qc.x(2)
    }
    let state = qc.run()
    var d = Array(repeating: 0.0, count: 4)
    for coin in 0...1 { for pos in 0..<4 { d[pos] += state[coin * 4 + pos].magnitudeSquared } }
    return d
}

print("\n4-site walk, coin |0⟩, 3 steps:  ", gateWalk(prepareCoin: false, steps: 3).map { String(format: "%.4f", $0) })
print("4-site walk, coin |+i⟩, 3 steps: ", gateWalk(prepareCoin: true, steps: 3).map { String(format: "%.4f", $0) })
// [0, 1, 0, 0]: certainty on site 1;  [0, 0.5, 0, 0.5]: an even split

// ------------------------------------------------------------
// §5 — Live view
// ------------------------------------------------------------
// Position distributions after 7 steps: quantum |0⟩ coin, quantum |+i⟩ coin, classical.
// Stateless views (no @State) — required for page code.

struct SiteBars: View {
    let title: String
    let values: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(values.indices, id: \.self) { site in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: 22, height: max(1, 90 * CGFloat(values[site])))
                        Text("\(site)")
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
            }
            .frame(height: 110, alignment: .bottom)
        }
        .padding(8)
    }
}

struct QuantumWalkView: View {
    let biased: [Double]
    let symmetric: [Double]
    let classical: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SiteBars(title: "quantum walk, coin |0⟩ (lopsided)", values: biased)
            SiteBars(title: "quantum walk, coin |+i⟩ (symmetric)", values: symmetric)
            SiteBars(title: "classical random walk", values: classical)
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    QuantumWalkView(biased: biased, symmetric: symmetric, classical: classicalDistribution(steps: 7))
        .frame(width: 520, height: 460)
)

//: [Next](@next)
