//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Single-qubit examples
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
