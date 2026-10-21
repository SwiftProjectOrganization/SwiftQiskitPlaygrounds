//: [Previous](@previous)
/*:
 # Applying a gate the textbook way

 The textbook way to apply a gate U to qubit t is to build `I ⊗ … ⊗ U ⊗ … ⊗ I` (a 2ⁿ × 2ⁿ
 matrix) and multiply: O(4ⁿ) memory and time per gate.

 This page does exactly that for a small example — a Hadamard on qubit 0 and RY(π/4) on
 qubit 2 of a 3-qubit register — checks the answer against `QuantumCircuit.run()`, and then
 counts what the approach costs as n grows. `02StateVectorCPU` shows how to avoid that cost.

 **Bit order.** Same as Core and page 02: qubit 0 is the most-significant bit, so it is the
 *leftmost* factor of the Kronecker product (`|q0 q1 q2⟩ ↔ index q0·4 + q1·2 + q2`).
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Embedding a 1-qubit gate in an n-qubit register
// ------------------------------------------------------------

/// Builds `I ⊗ … ⊗ U ⊗ … ⊗ I` with `u` as factor number `target` (0 = leftmost).
func embed(_ u: Matrix, on target: Int, qubits n: Int) -> Matrix {
    precondition((0..<n).contains(target), "target out of range")
    let identity2 = Matrix.identity(size: 2)
    var result = Matrix(rows: 1, cols: 1, repeating: .one)   // neutral element of ⊗
    for q in 0..<n {
        result = result ⊗ (q == target ? u : identity2)
    }
    return result
}

// ------------------------------------------------------------
// §2 — What the big matrix looks like
// ------------------------------------------------------------
// I ⊗ H ⊗ I on 3 qubits is 8×8 = 64 entries, but only 2 per row are non-zero.

let hMiddle = embed(HadamardGate.matrix, on: 1, qubits: 3)
print(hMiddle)

var nonZeros = 0
for r in 0..<hMiddle.rows {
    for c in 0..<hMiddle.cols where hMiddle[r, c] != .zero { nonZeros += 1 }
}
print("non-zero entries: \(nonZeros) of \(hMiddle.rows * hMiddle.cols)")
// non-zero entries: 16 of 64 — the other 48 multiplications are by zero

// ------------------------------------------------------------
// §3 — Apply H to qubit 0, then RY(π/4) to qubit 2, starting from |000⟩
// ------------------------------------------------------------

let n = 3
let hOn0 = embed(HadamardGate.matrix, on: 0, qubits: n)
let ryOn2 = embed(RYGate.matrix(theta: .pi / 4), on: 2, qubits: n)

var psi = [Complex](repeating: .zero, count: 1 << n)
psi[0] = .one                       // |000⟩

psi = hOn0.multiply(by: psi)        // (|000⟩ + |100⟩) / √2
psi = ryOn2.multiply(by: psi)       // then qubit 2 → cos(π/8)|0⟩ + sin(π/8)|1⟩

print(psi.map { $0.magnitudeSquared })
// ≈ [0.427, 0.073, 0, 0, 0.427, 0.073, 0, 0]
// cos²(π/8)/2 on indices 0 and 4, sin²(π/8)/2 on indices 1 and 5

// The two gates act on different qubits, so they can be fused into one operator
// H ⊗ I ⊗ RY(π/4) (a single Kronecker product) with the same result.
let fused = HadamardGate.matrix ⊗ Matrix.identity(size: 2) ⊗ RYGate.matrix(theta: .pi / 4)
var e0 = [Complex](repeating: .zero, count: 1 << n)
e0[0] = .one
let fusedPsi = fused.multiply(by: e0)
print("fused vs sequential max |Δ|:",
      zip(psi, fusedPsi).map { ($0 - $1).magnitude }.max() ?? 0)
// ~1e-16

// ------------------------------------------------------------
// §4 — Cross-check against Core's run()
// ------------------------------------------------------------

let circuit = QuantumCircuit(qubits: n)
circuit.h(0)
circuit.ry(.pi / 4, 2)
let coreState = circuit.run()

var maxDiff = 0.0
for i in 0..<(1 << n) {
    maxDiff = max(maxDiff, (psi[i] - coreState.amplitudes[i]).magnitude)
}
print("max |Δ| vs Core:", maxDiff)
// ~1e-16 — the explicit big-matrix product and Core agree amplitude for amplitude

// ------------------------------------------------------------
// §5 — The same example in O(2ⁿ): pair updates
// ------------------------------------------------------------
// U only mixes amplitudes whose indices differ in one bit b = n-1-qubit. Each of the 2ⁿ⁻¹
// pairs (i0, i1 = i0 + 2ᵇ) gets one 2×2 product — no big matrix, no multiplying by zero.
// (Page 02 builds this into `StateVectorCPU`; here it is bare, for 1-qubit gates only.)

func applyByPairs(_ u: Matrix, to qubit: Int, of state: inout [Complex], qubits n: Int) {
    let step = 1 << (n - 1 - qubit)         // distance between partners i0 and i1
    var block = 0
    while block < state.count {
        for k in 0..<step {
            let i0 = block + k, i1 = i0 + step
            let a0 = state[i0], a1 = state[i1]   // read both BEFORE writing
            state[i0] = u[0, 0] * a0 + u[0, 1] * a1
            state[i1] = u[1, 0] * a0 + u[1, 1] * a1
        }
        block += 2 * step
    }
}

var psiFast = [Complex](repeating: .zero, count: 1 << n)
psiFast[0] = .one                           // |000⟩
applyByPairs(HadamardGate.matrix, to: 0, of: &psiFast, qubits: n)
applyByPairs(RYGate.matrix(theta: .pi / 4), to: 2, of: &psiFast, qubits: n)

print(psiFast.map { $0.magnitudeSquared })
// ≈ [0.427, 0.073, 0, 0, 0.427, 0.073, 0, 0] — same as §3

print("max |Δ| vs big matrix (§3):",
      zip(psi, psiFast).map { ($0 - $1).magnitude }.max() ?? 0)
print("max |Δ| vs Core (§4):",
      zip(coreState.amplitudes, psiFast).map { ($0 - $1).magnitude }.max() ?? 0)
// ~1e-16 for both. Work per gate here: 4 pairs × 4 multiplies = 16, against 64 for the 8×8
// matrix. In general 2·2ⁿ vs 4ⁿ — at n = 20, ~2 million vs ~1.1 trillion — and the state
// vector is 16 MB where the matrix would be 16 TB. See `02StateVectorCPU`.

// ------------------------------------------------------------
// §6 — Live view: one Bloch sphere per qubit
// ------------------------------------------------------------
// `BlochVector(_:qubit:)` takes the reduced state of one qubit (a partial trace). The final
// state is a product state — H and RY(π/4) act on different qubits and nothing entangles
// them — so every arrow has length 1:
//   qubit 0: |+⟩ (x = 1), qubit 1: |0⟩ (z = 1),
//   qubit 2: RY(π/4)|0⟩ (x = sin(π/4) ≈ 0.707, z = cos(π/4) ≈ 0.707).
// `coreState` (§4) matches the big-matrix result `psi` to ~1e-16.
// Stateless view (no @State) — required for page code.

let blochSpheres: [(name: String, bloch: BlochVector)] = [
    ("qubit 0 (H)", BlochVector(coreState, qubit: 0)),
    ("qubit 1 (idle)", BlochVector(coreState, qubit: 1)),
    ("qubit 2 (RY(π/4))", BlochVector(coreState, qubit: 2))
]

struct QubitSpheresView: View {
    let spheres: [(name: String, bloch: BlochVector)]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(260)), count: 3), spacing: 16) {
            ForEach(spheres, id: \.name) { sphere in
                BlochSphereView(label: sphere.name, bloch: sphere.bloch)
            }
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    QubitSpheresView(spheres: blochSpheres)
        .frame(width: 840, height: 340)
)

//: [Next](@next)
