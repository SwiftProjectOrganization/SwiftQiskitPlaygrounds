//: [Previous](@previous)
/*:
 # Dirac notation and expectation values

 Follows Chapter 4 of the SwiftQiskitApp introduction (`Docs/Introduction/04-DiracNotation.md`).

 `Ket` is a typealias of `StateVector`; `Bra` is its conjugate-transpose. The whole chapter
 rests on one type discipline:
 - a bra before a ket (`⟨φ|ψ⟩`) is a **number**, the overlap of two states;
 - a ket before a bra (`|ψ⟩⟨φ|`) is a **matrix**, a projector or more general operator.

 The three Pauli expectation values `⟨ψ|X|ψ⟩`, `⟨ψ|Y|ψ⟩`, `⟨ψ|Z|ψ⟩` are exactly a qubit's
 Bloch coordinates.

 `†` is U+2020 (⌥T on a US keyboard). ASCII equivalents: `Bra(ket)`, `bra.ket`, `matrix.adjoint`.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §4.2 — Ket, Bra, and the dagger
// ------------------------------------------------------------

let plus = Ket.plus
print(plus)
// |0⟩: 0.7071067811865475 |1⟩: 0.7071067811865475
print(plus†)
// ⟨0|: 0.7071067811865475 ⟨1|: 0.7071067811865475

print((plus†)† == plus)
// true — exactly: normalize() skips rescaling when the length is already within 1e-12 of 1

let asciiBra = Bra(plus)               // same as plus†
let asciiKet = asciiBra.ket            // same as asciiBra†
print(asciiKet == plus)
// true

// ------------------------------------------------------------
// §4.3 — Inner and outer products
// ------------------------------------------------------------

print(Bra("0") * Ket("0"))
print(Bra("0") * Ket("1"))
print(Ket.plus† * Ket.zero)
// 1.0, 0.0, 0.7071067811865475 — orthonormal basis; |+⟩ has partial overlap with |0⟩

let ketPhi = Ket([Complex(0.6), Complex(0.8)])
print(ketPhi† * ketPhi)
// 1.0

// Conjugate symmetry: ⟨φ|ψ⟩ = ⟨ψ|φ⟩*
let forward = ketPhi† * Ket.plusI
let backward = Ket.plusI† * ketPhi
print(forward)
print(backward.conjugate)
// both 0.42426406871192845 + 0.565685424949238i

// ------------------------------------------------------------
// §4.4 — Projectors and adjoints
// ------------------------------------------------------------

let p0 = Ket.zero * Ket.zero†
let p1 = Ket.one * Ket.one†
print(p0)
print(p1)
// [1, 0] [0, 0]   and   [0, 0] [0, 1]

print(p0† == p0)               // Hermitian: true
print((p0 * p0) == p0)         // idempotent: true
print(p0 + p1 == Matrix.identity(size: 2))   // complete: true

// Born rule as a bra–projector–ket sandwich: ⟨φ|0⟩⟨0|φ⟩ = |⟨0|φ⟩|²
let born = ketPhi† * p0 * ketPhi
print(born, ketPhi.probabilities[0])
// 0.36 0.36

// H and the Paulis are Hermitian. † only transposes/conjugates, so == is exact here.
print(HadamardGate.matrix† == HadamardGate.matrix)   // true
print(PauliYGate.matrix† == PauliYGate.matrix)       // true

// Once multiplication enters, rounding is back: compare with a tolerance.
func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
    var m = 0.0
    for i in 0..<a.rows { for j in 0..<a.cols {
        m = max(m, (a[i, j] - b[i, j]).magnitude)
    } }
    return m
}
print(HadamardGate.matrix† * HadamardGate.matrix)
// [0.9999999999999998, 0] [0, 0.9999999999999998]
print(maxDiff(HadamardGate.matrix† * HadamardGate.matrix, Matrix.identity(size: 2)))
// 2.220446049250313e-16

// ------------------------------------------------------------
// §4.5 — Pauli expectation values are the Bloch coordinates
// ------------------------------------------------------------

// |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ} sin(θ/2)|1⟩
func makeState(theta: Double, phi: Double) -> StateVector {
    StateVector([
        Complex(cos(theta / 2)),
        Complex(sin(theta / 2) * cos(phi), sin(theta / 2) * sin(phi))
    ])
}
let theta = Double.pi / 3
let phi = Double.pi / 4
let psi = makeState(theta: theta, phi: phi)

// A bra against a basis ket extracts one amplitude: ⟨0|ψ⟩ = α, ⟨1|ψ⟩ = β
print(Bra("0") * psi)
print(Bra("1") * psi)
// 0.8660254037844387
// 0.35355339059327373 + 0.3535533905932737i

let expectX = psi† * PauliXGate.matrix * psi
let expectY = psi† * PauliYGate.matrix * psi
let expectZ = psi† * PauliZGate.matrix * psi
print(expectX, expectY, expectZ)
print(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta))
// 0.6123724356957945 0.6123724356957945 0.5000000000000002 (no `i`: Hermitian ⇒ real)
// 0.6123724356957946 0.6123724356957945 0.5000000000000001

let bloch = BlochVector(psi)
print(bloch.x, bloch.y, bloch.z)
// Same three numbers, straight from the amplitudes: x = 2Re(ᾱβ), y = 2Im(ᾱβ), z = |α|²−|β|²

// ------------------------------------------------------------
// §4.6 — Multi-qubit kets and bras
// ------------------------------------------------------------

print(Ket("01") == Ket.zero ⊗ Ket.one)
// true — qubit 0 is the most-significant (leftmost) bit

print(Ket.plus† ⊗ Ket.one† == (Ket.plus ⊗ Ket.one)†)
// true — conjugation distributes over ⊗ exactly

// Ket ⊗ Bra is the outer product spelled with ⊗
print(Ket.zero ⊗ Ket.zero† == Ket.zero * Ket.zero†)
// true
let asym = Ket("10") ⊗ Bra("0")
print(asym.rows, asym.cols)
// 4 2 — ⊗ places no constraint on matching dimensions

// A Bell-state amplitude as a bra–ket product
let bellCircuit = QuantumCircuit(qubits: 2)
bellCircuit.h(0)
bellCircuit.cx(0, 1)
let bellState = bellCircuit.run()
print(Bra("11") * bellState)
// 0.7071067811865475 — ⟨11|Φ⁺⟩ = 1/√2

// ------------------------------------------------------------
// §4.7 — The same |ψ⟩ built from gates (RY then P)
// ------------------------------------------------------------

var stages: [(name: String, bloch: BlochVector)] = []
let circuit = QuantumCircuit(qubits: 1)
stages.append(("|0⟩", BlochVector(circuit.run())))
circuit.ry(.pi / 3, 0)
stages.append(("RY(π/3)", BlochVector(circuit.run())))
circuit.p(.pi / 4, 0)
let state = circuit.run()
stages.append(("P(π/4) → |ψ⟩", BlochVector(state)))

print(state.amplitudes, state.probabilities)
// [0.8660254037844387, 0.35355339059327373 + 0.3535533905932737i] [0.75, 0.25]
let gateBloch = BlochVector(state, qubit: 0)
print(gateBloch.x, gateBloch.y, gateBloch.z, gateBloch.theta, gateBloch.phi)
// 0.612… 0.612… 0.5 1.047… 0.785… — identical to §4.5

// ------------------------------------------------------------
// Try it yourself
// ------------------------------------------------------------

// 1. ⟨+i|Z|+i⟩ ≈ 0. Why? ⟨ψ|Z|ψ⟩ = |α|² − |β|², and |+i⟩ has |α|² = |β|² = 0.5.
print(Ket.plusI† * PauliZGate.matrix * Ket.plusI)
// 0.0

// 2. Why is (|ψ⟩†)† == |ψ⟩ exactly true? normalize() skips rescaling for an already
//    normalized vector, so no rounding ever enters.

// 3. Ket.zero * Ket.zero† is a Matrix (the projector |0⟩⟨0|);
//    Ket.zero† * Ket.zero is a Complex (⟨0|0⟩ = 1).

// 4. 0.6² + 0.8² = 1 exactly, so normalize() skips rescaling and the self-overlap is exact;
//    [0.5, 0.5] is rescaled by 1/√0.5, which is where the ~1e-16 error comes from.
print(ketPhi† * ketPhi)
print(Ket([Complex(0.5), Complex(0.5)])† * Ket([Complex(0.5), Complex(0.5)]))
// 1.0   0.9999999999999998

// ------------------------------------------------------------
// Live view — the stages of §4.7 on Bloch spheres
// ------------------------------------------------------------
// Stateless view (no @State) — required for page code.

struct DiracStagesView: View {
    let stages: [(name: String, bloch: BlochVector)]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(260)), count: 3), spacing: 16) {
            ForEach(stages, id: \.name) { stage in
                BlochSphereView(label: stage.name, bloch: stage.bloch)
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    DiracStagesView(stages: stages)
        .frame(width: 840, height: 340)
)

//: [Next](@next)
