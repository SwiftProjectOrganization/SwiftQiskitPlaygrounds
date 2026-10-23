//: [Previous](@previous)
/*:
 # Complex numbers and complex matrices

 Quantum amplitudes are complex numbers, so `Complex` is the scalar type that every
 `StateVector` and gate matrix is built from.

 §1 covers `Complex` arithmetic: construction, `*`, `/` and `conjugate`, and division
 written by hand as `z · w̄ / |w|²`.
 §2 moves on to `Matrix` with `Complex` entries, the type SwiftQiskit uses for gates. It
 shows the dagger `†` (conjugate transpose), `*` and `⊗` on non-square shapes.

 For a fuller tour (magnitude and phase, inner products, unitary and Hermitian matrices),
 see the SwiftQiskit `40ComplexAndMatrices` page.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Complex arithmetic examples
// ------------------------------------------------------------
//

let c1 = Complex(4, 3)
print(c1)

let c2 = 5.0
let c3 = Complex(2, 1)

let c4 = c2 * c1
print(c4)

let c5 = c1 * c3
print(c5)

let c6 = c1 / c3
print(c6)

// Complex(5.0) is the magnitude of c3. These properties are
// added to the StateVector struct.

let c7 = c1 * c3.conjugate / Complex(5.0)

//------------------------------------------------------------
// §2 — Complex matrix examples - what is used in SwiftQiskit
// ------------------------------------------------------------

let mat1 = Matrix([[Complex(1,-2), Complex(2, -1)],
                   [Complex(3), Complex(4)]])
let m1 = Matrix([[Complex(1), Complex(2, -3)],])

let m2 = Matrix([[Complex(1,2)], [Complex(2,3)]])

print(m1 ⊗ mat1)

print(m1† ⊗ mat1)

print(mat1 * m2)

print(mat1 ⊗ m2)

//: [Next](@next)
