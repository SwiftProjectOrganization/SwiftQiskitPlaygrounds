//: [Previous](@previous)
/*:
 # Noise, Density Matrices and Channels

 Where the state-vector picture stops being enough: a qubit that talks to something you
 don't track is a **mixture**, described by a density matrix `ρ`.

 - A pure state is `ρ = Ket * Bra`; a mixture is `Σ pᵢ |ψᵢ⟩⟨ψᵢ|`. Purity is `Tr(ρ²)`.
 - A channel is `ρ' = Σ Kᵢ ρ Kᵢ†` with `Σ Kᵢ†Kᵢ = I`, checked before it is trusted.
 - Four channels: bit-flip, phase-flip, depolarizing and amplitude damping.
 - Phase-flip(p) decays coherence as `(1 − 2p)ⁿ`; amplitude damping pulls toward `|0⟩`.
 - A Monte-Carlo unraveling reproduces a channel with ordinary pure-state code.
 - A Bell pair is pure, but its reduced qubit has `|r| = 0` and entropy 1 bit.
 - A Bloch vector shorter than 1 is a mixed state, drawn with `BlochVector(x:y:z:)`.

 Limit: this page builds `ρ` and the channels as plain `Matrix` values, so purity and
 entropy are computed by hand from traces and the Bloch magnitude.

 Follows Chapter 21 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

func trace(_ a: Matrix) -> Complex {
    var s = Complex.zero
    for i in 0..<a.rows { s = s + a[i, i] }
    return s
}
func rho(_ psi: Ket) -> Matrix { psi * (psi†) }
func purity(_ r: Matrix) -> Double { trace(r * r).real }

let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix
let H = HadamardGate.matrix

// ------------------------------------------------------------
// §1 — From state vectors to density matrices
// ------------------------------------------------------------

let rhoPlus = rho(Ket.plus)
let rhoMix = (rho(Ket.zero) + rho(Ket.one)) * 0.5
print("rho(|+>): diag \(fmt(rhoPlus[0, 0].real)), \(fmt(rhoPlus[1, 1].real))   off-diag \(rhoPlus[0, 1])")
print("rho(mix): diag \(fmt(rhoMix[0, 0].real)), \(fmt(rhoMix[1, 1].real))   off-diag \(rhoMix[0, 1])")
print("purity: |+> = \(fmt(purity(rhoPlus))),  mixture = \(fmt(purity(rhoMix)))")
// same Z statistics, but only |+⟩ has the off-diagonal coherence

// ------------------------------------------------------------
// §2 — Kraus channels
// ------------------------------------------------------------

func bitFlipKraus(_ p: Double) -> [Matrix] { [I2 * (1 - p).squareRoot(), X * p.squareRoot()] }
func phaseFlipKraus(_ p: Double) -> [Matrix] { [I2 * (1 - p).squareRoot(), Z * p.squareRoot()] }
func depolarizingKraus(_ p: Double) -> [Matrix] {
    [I2 * (1 - 0.75 * p).squareRoot(), X * (p / 4).squareRoot(),
     Y * (p / 4).squareRoot(), Z * (p / 4).squareRoot()]
}
func ampDampingKraus(_ g: Double) -> [Matrix] {
    var k0 = Matrix(rows: 2, cols: 2)
    k0[0, 0] = .one; k0[1, 1] = Complex((1 - g).squareRoot())
    var k1 = Matrix(rows: 2, cols: 2)
    k1[0, 1] = Complex(g.squareRoot())
    return [k0, k1]
}

func traceResidual(_ ks: [Matrix]) -> Double {
    var sum = Matrix(rows: 2, cols: 2)
    for k in ks { sum = sum + (k†) * k }
    let diff = sum - I2
    var maxAbs = 0.0
    for i in 0..<2 { for j in 0..<2 { maxAbs = max(maxAbs, diff[i, j].magnitude) } }
    return maxAbs
}

print("\nΣKᵢ†Kᵢ − I max residual, p = 0.3:")
print("  bit-flip:      \(String(format: "%.2e", traceResidual(bitFlipKraus(0.3))))")
print("  phase-flip:    \(String(format: "%.2e", traceResidual(phaseFlipKraus(0.3))))")
print("  depolarizing:  \(String(format: "%.2e", traceResidual(depolarizingKraus(0.3))))")
print("  amp-damping:   \(String(format: "%.2e", traceResidual(ampDampingKraus(0.3))))")
// all four are trace-preserving to floating-point precision

func applyChannel(_ ks: [Matrix], _ r: Matrix) -> Matrix {
    var out = Matrix(rows: 2, cols: 2)
    for k in ks { out = out + k * r * (k†) }
    return out
}

// ------------------------------------------------------------
// §3 — Coherence decay
// ------------------------------------------------------------

print("\nn    off-diag (measured)   (1-2p)ⁿ predicted   [p = 0.1]")
for n in [1, 5, 10, 20] {
    var r = rhoPlus
    for _ in 1...n { r = applyChannel(phaseFlipKraus(0.1), r) }
    let predicted = 0.5 * pow(0.8, Double(n))
    print("\(n)     \(fmt(r[0, 1].real))              \(fmt(predicted))   purity \(fmt(purity(r)))")
}
let fullyDepolarized = applyChannel(depolarizingKraus(1.0), rho(Ket.zero))
print("\nfully depolarized (p=1) on |0>: diag \(fmt(fullyDepolarized[0, 0].real)), \(fmt(fullyDepolarized[1, 1].real)), purity \(fmt(purity(fullyDepolarized)))")
// maximally mixed in one step: purity exactly 0.5

// ------------------------------------------------------------
// §4 — Amplitude damping
// ------------------------------------------------------------

func blochOf(_ r: Matrix) -> (x: Double, y: Double, z: Double) {
    (trace(r * X).real, trace(r * Y).real, trace(r * Z).real)
}

var damped = rhoPlus
for _ in 1...20 { damped = applyChannel(ampDampingKraus(0.2), damped) }
let dampedBloch = blochOf(damped)
print("\n|+> after 20 rounds amp damping (γ = 0.2): (x, y, z) = (\(fmt(dampedBloch.x)), \(fmt(dampedBloch.y)), \(fmt(dampedBloch.z)))  purity \(fmt(purity(damped)))")
// x = 0.8¹⁰ = 0.107374, z = 1 − 0.8²⁰ = 0.988471

// ------------------------------------------------------------
// §5 — Monte-Carlo unraveling
// ------------------------------------------------------------

func monteCarloPhaseFlipXBasis(_ p: Double, shots: Int) -> Double {
    var plusCount = 0
    for _ in 0..<shots {
        var s = StateVector.plus
        if Double.random(in: 0..<1) < p { s.apply(Z) }
        s.apply(H)
        if s.measure() == 0 { plusCount += 1 }
    }
    return Double(plusCount) / Double(shots)
}

let mcP = monteCarloPhaseFlipXBasis(0.1, shots: 20000)
print("\nMonte-Carlo phase-flip(0.1) on |+>, 20000 shots: P(+x) = \(fmt(mcP))")
print("exact prediction (1+(1-2p))/2 = \(fmt((1 + (1 - 2 * 0.1)) / 2))")
// statistical: within about ±0.002 of 0.900000

// ------------------------------------------------------------
// §6 — Entanglement entropy from a Bell pair's reduced state
// ------------------------------------------------------------

var bell = StateVector(qubits: 2)
bell.apply(H.tensor(I2))
bell.apply(CNOTGate.matrix(qubits: 2, control: 0, target: 1))
let rhoBell = rho(bell)

func partialTraceLast(_ r: Matrix) -> Matrix {
    var out = Matrix(rows: 2, cols: 2)
    for i in 0..<2 {
        for j in 0..<2 {
            var s = Complex.zero
            for k in 0..<2 { s = s + r[i * 2 + k, j * 2 + k] }
            out[i, j] = s
        }
    }
    return out
}

func entropy(of r: Matrix) -> Double {
    let b = blochOf(r)
    let mag = (b.x * b.x + b.y * b.y + b.z * b.z).squareRoot()
    let l1 = (1 + mag) / 2, l2 = (1 - mag) / 2
    func log2safe(_ v: Double) -> Double { v <= 0 ? 0 : log2(v) }
    return -(l1 * log2safe(l1) + l2 * log2safe(l2))
}

let rhoA = partialTraceLast(rhoBell)
print("\nBell pair |Φ⁺⟩: full-state purity = \(fmt(purity(rhoBell)))")
print("qubit 0's reduced state ρ_A: diag \(fmt(rhoA[0, 0].real)), \(fmt(rhoA[1, 1].real)), purity \(fmt(purity(rhoA))), entropy \(fmt(entropy(of: rhoA))) bits")
var product = StateVector(qubits: 2)
product.apply(H.tensor(I2))
print("product state |+⟩⊗|0⟩: ρ_A entropy = \(fmt(entropy(of: partialTraceLast(rho(product))))) bits")
// the full state is pure, but the marginal is maximally mixed: entropy 1 bit

// ------------------------------------------------------------
// §7 — A live Bloch gallery
// ------------------------------------------------------------
// The pure |+⟩, its dephased image, the damped state, and the fully depolarized origin.
// Stateless views (no @State) — required for page code.

var dephased = rhoPlus
for _ in 1...5 { dephased = applyChannel(phaseFlipKraus(0.1), dephased) }
let dephasedBloch = blochOf(dephased)

struct NoiseGalleryView: View {
    let points: [(String, BlochVector)]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(points.indices, id: \.self) { i in
                BlochSphereView(label: points[i].0, bloch: points[i].1, size: 150)
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    NoiseGalleryView(points: [
        ("|+⟩ pure", BlochVector(x: 1, y: 0, z: 0)),
        ("dephased ×5", BlochVector(x: dephasedBloch.x, y: dephasedBloch.y, z: dephasedBloch.z)),
        ("damped ×20", BlochVector(x: dampedBloch.x, y: dampedBloch.y, z: dampedBloch.z)),
        ("depolarized", BlochVector(x: 0, y: 0, z: 0))
    ])
    .frame(width: 680, height: 220)
)

//: [Next](@next)
