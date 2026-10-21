//: [Previous](@previous)

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
// §2 — Matrix examples
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
