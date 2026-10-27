//: [Previous](@previous)
/*:
 # Complex numbers and matrices

 Follows Chapter 2 of the SwiftQiskitApp introduction (`Docs/Introduction/02-ComplexAndMatrices.md`).

 Quantum amplitudes are complex numbers, gates are complex matrices, and `Complex` and
 `Matrix` are the types everything else is built from.

 - §1 `Complex` arithmetic: `*`, `/`, `conjugate`, `magnitudeSquared`, and the Born rule.
 - §2 Magnitude and phase: `argument`, `Complex(argument:)`, `Complex.exp`, `Complex.pow`.
 - §3 Plain `[Complex]` vectors: `adding`, `scaled(by:)`, `inner`, `norm`, `normalized()`.
 - §4 Matrices as transformations, and why the order of a product matters.
 - §5 Unitary matrices, and why `==` is the wrong test.
 - §6 The tensor product `⊗`, and what it has to do with `QuantumCircuit`.

 Needs SwiftQiskit 0.9.0 or later for the polar form and the `[Complex]` methods.

 Limits: `Matrix` equality is exact on `Double`s. Dense matrices only scale to a few qubits.

 `01Matrices` covers the real-valued `GenericMatrix`; `11TensorProducts` treats `⊗` in depth.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Complex arithmetic
// ------------------------------------------------------------

let a = Complex(3, 4)
let b = Complex(1, -2)
print("a * b = \(a * b)")   // 11.0 - 2.0i
print("a / b = \(a / b)")   // -1.0 + 2.0i

// z * z.conjugate is always real and equals |z|².
let z = Complex(3, 2)
print("z * z̄ = \(z * z.conjugate), |z|² = \(z.magnitudeSquared)")

// description drops a zero imaginary part, so i * i prints as -1.0.
print("i * i = \(Complex.i * Complex.i)")

// Born rule: probability is the magnitude squared of an amplitude.
// Not exactly 0.5, because 1/√2 is rounded.
let amp = Complex(1.0 / sqrt(2.0), 0)
print("|amp|² = \(amp.magnitudeSquared)")

// ------------------------------------------------------------
// §2 — Magnitude and phase
// ------------------------------------------------------------

// Complex(argument:) builds the unit phase e^{iθ} directly from an angle.
let theta = Double.pi / 3
print("rad2deg(theta) = \(rad2deg(theta))")
let phase = Complex(argument: theta)
print(phase, phase.magnitude)
print(PhaseGate.matrix(theta: theta)[1, 1])
print("argument = \(phase.argument)")   // θ again, up to rounding

// Magnitude and argument together: 3 + 4i has magnitude 5.
let polar = Complex(3, 4)
print(polar.magnitude, polar.argument)
print(Complex(magnitude: polar.magnitude, argument: polar.argument))

// e^{iπ} = -1; the imaginary part is rounding, about 1.2e-16.
print(Complex.exp(Complex(0, Double.pi)))
print(Complex.pow(.i, 4), Complex.pow(Complex(1, 1), 2))   // 1.0, 2.0i

// ------------------------------------------------------------
// §3 — Vectors of amplitudes
// ------------------------------------------------------------

let zero: [Complex] = [.one, .zero]
let one: [Complex] = [.zero, .one]
let plus: [Complex] = [Complex(1 / sqrt(2), 0), Complex(1 / sqrt(2), 0)]
print(zero, one, plus)

print(zero.adding(one).normalized())   // |0⟩ + |1⟩, normalized: equal superposition
print([Complex(1, 0), Complex(0, 1)].adding([Complex(2, 0), Complex(0, -1)]))
print([Complex(1, 0), Complex(2, 0)].scaled(by: Complex.i))

// The inner product conjugates the first vector: ⟨a|b⟩ = Σ conj(aᵢ) bᵢ.
let v: [Complex] = [Complex(1, 0), Complex.i]
let w: [Complex] = [Complex(1, 0), Complex(0, -1)]
print("⟨v|w⟩ = \(v.inner(w))")   // 0, so v and w are orthogonal

let raw: [Complex] = [Complex(1, 0), Complex.i]
print("norm(raw) = \(raw.norm)")
let normalized = raw.normalized()
print(normalized, normalized.norm)

// ------------------------------------------------------------
// §4 — Matrices as transformations
// ------------------------------------------------------------

let H = HadamardGate.matrix
print(H[0, 0], H.rows, H.cols)
print(H.multiply(by: [Complex.one, Complex.zero]))

// Apply A first, then B: the combined matrix is B * A.
let Z = PauliZGate.matrix
let ket0: [Complex] = [.one, .zero]
print((Z * H).multiply(by: ket0))   // H then Z: |−⟩
print((H * Z).multiply(by: ket0))   // Z then H: |+⟩

// ------------------------------------------------------------
// §5 — Unitary matrices, and why == lies
// ------------------------------------------------------------

let I2 = Matrix.identity(size: 2)
for (name, g) in [("H", HadamardGate.matrix), ("X", PauliXGate.matrix),
                  ("S", SGate.matrix), ("T", TGate.matrix)] {
    // == is exact: only H misses I, by about 2.2e-16.
    print(name, g.adjoint * g == I2, g.isUnitary())
}

func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
    var m = 0.0
    for i in 0..<a.rows {
        for j in 0..<a.cols {
            m = max(m, (a[i, j] - b[i, j]).magnitude)
        }
    }
    return m
}

print(maxDiff(H.adjoint * H, I2))

// ------------------------------------------------------------
// §6 — The tensor product
// ------------------------------------------------------------

// ⊗ places no constraint on shapes: m×n ⊗ p×q gives mp×nq.
let mat1 = Matrix([[Complex(1), Complex(2)], [Complex(3), Complex(4)]])
print(mat1 ⊗ H)
print(H ⊗ I2)

let row = Matrix([[Complex(1), Complex(2, -3)]])
let col = Matrix([[Complex(1, 2)], [Complex(2, 3)]])
print(row ⊗ mat1)    // 1×2 ⊗ 2×2 gives 2×4
print(row† ⊗ mat1)   // 2×1 ⊗ 2×2 gives 4×2
print(mat1 * col)
print(mat1 ⊗ col)

// H on qubit 0 of a 2-qubit circuit computes H ⊗ I.
let qc = QuantumCircuit(qubits: 2)
qc.h(0)
print(qc.run().amplitudes)
print((H ⊗ I2).multiply(by: [Complex.one, .zero, .zero, .zero]))

//: [Next](@next)
