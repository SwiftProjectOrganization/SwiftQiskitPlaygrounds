//: [Previous](@previous)
/*:
 # Tensor products and composite systems

 Combining qubits multiplies dimensions instead of adding them. `⊗` is the composition rule
 behind every multi-qubit state and gate.

 - On **state vectors**, `⊗` combines two registers: `|0⟩ ⊗ |0⟩ = |00⟩`.
 - On **matrices**, `⊗` embeds a gate: `H ⊗ I₂` is exactly what `h(0)` builds on 2 qubits.
 - `⊗` is **not commutative**: the left operand lands in the high-order bits (qubit 0).
 - Mixed-product identity: `(A ⊗ B)(x ⊗ y) = (Ax) ⊗ (By)`.
 - Entangling gates and entangled states are exactly the ones that **do not factor**.

 Follows Chapter 11 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func maxDiff(_ a: [Complex], _ b: [Complex]) -> Double {
    zip(a, b).map { ($0 - $1).magnitude }.max() ?? 0
}

// ------------------------------------------------------------
// §1 — ⊗ on state vectors
// ------------------------------------------------------------

let zero1 = StateVector(qubits: 1)
print("|0⟩ ⊗ |0⟩ == |00⟩ ->", zero1 ⊗ zero1 == StateVector(qubits: 2))
// true

var plus = StateVector(qubits: 1)
plus.apply(HadamardGate.matrix)
let combined = plus ⊗ zero1
let qcH0 = QuantumCircuit(qubits: 2); qcH0.h(0)
print("(H|0⟩) ⊗ |0⟩:", combined.amplitudes)
print("h(0) circuit: ", qcH0.run().amplitudes)
print("max diff:", maxDiff(combined.amplitudes, qcH0.run().amplitudes))
// identical, max diff 0.0

// Not commutative: left operand is qubit 0.
print("plus ⊗ zero:", (plus ⊗ zero1).amplitudes)  // [0.707, 0, 0.707, 0]
print("zero ⊗ plus:", (zero1 ⊗ plus).amplitudes)  // [0.707, 0.707, 0, 0]

var one1 = StateVector(qubits: 1)
one1.apply(PauliXGate.matrix)
print("|1⟩ ⊗ |0⟩ amplitudes:", (one1 ⊗ zero1).amplitudes)  // [0, 0, 1, 0]

// StateVector.description does not zero-pad labels: |0⟩ and |1⟩ here mean |00⟩ and |01⟩.
print(combined.description)

// ------------------------------------------------------------
// §2 — ⊗ on matrices: embedding a gate
// ------------------------------------------------------------

let i2 = Matrix.identity(size: 2)
print("I₂ ⊗ I₂ == I₄ ->", i2 ⊗ i2 == Matrix.identity(size: 4))

let hi = HadamardGate.matrix ⊗ i2
print("H ⊗ I₂ =")
print(hi)  // -0.0 entries are ordinary signed zeros

let a23 = Matrix(rows: 2, cols: 3, repeating: .one)
let b22 = Matrix(rows: 2, cols: 2, repeating: .i)
let shape = a23.tensor(b22)
print("(2×3) ⊗ (2×2) -> \(shape.rows)×\(shape.cols)")  // 4×6

let qcApplyHI = QuantumCircuit(qubits: 2); qcApplyHI.apply(hi)
print("apply(H ⊗ I₂):", qcApplyHI.run().amplitudes)
print("h(0):         ", qcH0.run().amplitudes)

let qcApplyHH = QuantumCircuit(qubits: 2)
qcApplyHH.apply(HadamardGate.matrix ⊗ HadamardGate.matrix)
let qcH01 = QuantumCircuit(qubits: 2); qcH01.h(0); qcH01.h(1)
print("apply(H ⊗ H):", qcApplyHH.run().amplitudes)
print("h(0);h(1):   ", qcH01.run().amplitudes)

var fourH = HadamardGate.matrix
for _ in 1..<4 { fourH = fourH.tensor(HadamardGate.matrix) }
let qcApply4 = QuantumCircuit(qubits: 4); qcApply4.apply(fourH)
let qcH4 = QuantumCircuit(qubits: 4)
qcH4.h(0); qcH4.h(1); qcH4.h(2); qcH4.h(3)
print("H⊗H⊗H⊗H vs four h calls, max diff:",
      maxDiff(qcApply4.run().amplitudes, qcH4.run().amplitudes))

// n tensored 2×2 factors: 4ⁿ entries.
for n in 1...4 {
    var m = i2
    for _ in 1..<n { m = m.tensor(i2) }
    print("n=\(n): \(m.rows)×\(m.cols) = \(m.rows * m.cols) entries")
}

// ------------------------------------------------------------
// §3 — Mixed-product identity
// ------------------------------------------------------------

func kronVector(_ u: [Complex], _ v: [Complex]) -> [Complex] {
    u.flatMap { ui in v.map { ui * $0 } }
}
let xv: [Complex] = [Complex(0.6), Complex(0.8)]
let yv: [Complex] = [.zero, .one]
let lhs = (PauliXGate.matrix ⊗ HadamardGate.matrix).multiply(by: kronVector(xv, yv))
let rhs = kronVector(PauliXGate.matrix.multiply(by: xv), HadamardGate.matrix.multiply(by: yv))
print("max |(X⊗H)(x⊗y) − (Xx)⊗(Hy)| =", maxDiff(lhs, rhs))
// 0.0

// ------------------------------------------------------------
// §4 — Entangling gates don't factor
// ------------------------------------------------------------
// A ⊗ B has four 2×2 blocks that are all scalar multiples of each other.

func blocks(_ m: Matrix) -> [[Complex]] {
    var result: [[Complex]] = []
    for bi in 0..<2 {
        for bj in 0..<2 {
            var block: [Complex] = []
            for i in 0..<2 { for j in 0..<2 { block.append(m[bi * 2 + i, bj * 2 + j]) } }
            result.append(block)
        }
    }
    return result
}

func isScalarMultiple(_ a: [Complex], _ b: [Complex], tolerance: Double = 1e-9) -> Bool {
    for i in 0..<a.count {
        for j in 0..<a.count where (a[i] * b[j] - a[j] * b[i]).magnitude > tolerance {
            return false
        }
    }
    return true
}

func isBlockProportional(_ m: Matrix) -> Bool {
    let bs = blocks(m)
    return bs.allSatisfy { isScalarMultiple($0, bs[0]) }
}

let cnot = CNOTGate.matrix(qubits: 2, control: 0, target: 1)
print("H ⊗ I₂ block-proportional:", isBlockProportional(hi))   // true
print("CNOT block-proportional:", isBlockProportional(cnot))     // false

// ------------------------------------------------------------
// §5 — Entangled states don't factor
// ------------------------------------------------------------
// Product states satisfy α₀₀·α₁₁ = α₀₁·α₁₀.

func factorCheck(_ label: String, _ state: StateVector) {
    let p = state[0] * state[3]
    let c = state[1] * state[2]
    print("\(label): a00*a11 = \(p), a01*a10 = \(c), diff = \((p - c).magnitude)")
}

factorCheck("|00⟩", QuantumCircuit(qubits: 2).run())
factorCheck("|+0⟩", qcH0.run())
factorCheck("|++⟩", qcH01.run())

let ryProduct = QuantumCircuit(qubits: 2)
ryProduct.ry(0.9, 0); ryProduct.ry(1.3, 1)
factorCheck("ry(0.9,0);ry(1.3,1)", ryProduct.run())

let bell = QuantumCircuit(qubits: 2); bell.h(0); bell.cx(0, 1)
factorCheck("Bell", bell.run())   // diff 0.5

let bellX = QuantumCircuit(qubits: 2); bellX.h(0); bellX.cx(0, 1); bellX.x(1)
factorCheck("Bell;x(1)", bellX.run())  // diff still 0.5

// ------------------------------------------------------------
// §6 — Live view
// ------------------------------------------------------------
// Matrix grids (|entry| shading, 2×2 blocks outlined) for H ⊗ I₂ and CNOT,
// above Bloch spheres for |++⟩ (|r| = 1) and Bell (|r| = 0).
// Stateless views (no @State) — required for page code.

struct MatrixGrid: View {
    let title: String
    let matrix: Matrix

    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.headline)
            VStack(spacing: 1) {
                ForEach(0..<matrix.rows, id: \.self) { r in
                    HStack(spacing: 1) {
                        ForEach(0..<matrix.cols, id: \.self) { c in
                            let v = min(matrix[r, c].magnitude, 1)
                            Text(String(format: "%.2f", v))
                                .font(.system(size: 10, design: .monospaced))
                                .frame(width: 38, height: 28)
                                .background(Color.accentColor.opacity(v))
                                .border(Color.secondary.opacity(0.4), width: 0.5)
                        }
                    }
                }
            }
            .overlay {
                // Divider lines between the 2×2 blocks.
                ZStack {
                    Rectangle().fill(Color.primary).frame(width: 2)
                    Rectangle().fill(Color.primary).frame(height: 2)
                }
            }
        }
    }
}

struct TensorView: View {
    let product: [BlochVector]
    let bell: [BlochVector]

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                MatrixGrid(title: "H ⊗ I₂ (blocks proportional)", matrix: HadamardGate.matrix ⊗ Matrix.identity(size: 2))
                MatrixGrid(title: "CNOT (blocks differ)", matrix: CNOTGate.matrix(qubits: 2, control: 0, target: 1))
            }
            HStack(spacing: 8) {
                ForEach(product.indices, id: \.self) { q in
                    BlochSphereView(label: "|++⟩ q\(q)", bloch: product[q], size: 130)
                }
                ForEach(bell.indices, id: \.self) { q in
                    BlochSphereView(label: "Bell q\(q)", bloch: bell[q], size: 130)
                }
            }
        }
        .padding()
    }
}

let productState = qcH01.run()
let bellState = bell.run()

PlaygroundPage.current.setLiveView(
    TensorView(
        product: (0..<2).map { BlochVector(productState, qubit: $0) },
        bell: (0..<2).map { BlochVector(bellState, qubit: $0) }
    )
    .frame(width: 720, height: 560)
)

//: [Next](@next)
