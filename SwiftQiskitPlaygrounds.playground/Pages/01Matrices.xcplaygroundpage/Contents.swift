//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Matrices examples
// ------------------------------------------------------------

// SwiftQiskit's Matrix is only defined for Complex elements.

// Use GenericMatrix() to work with Double elements, making
// Matrix generic, i.e. also accepting Floats and Ints
// would generate ambiguities on Float and Int (e.g. on
// amplitude).

// As you can't easily mix types, later playgounds
// in this project always use Complex(2), etc.

let m0 = GenericMatrix([[Double(1), Double(2)], [Double(3), Double(4)]])
print(m0)

let m1 = GenericMatrix([[Double(1), Double(2)]])
print(m1)

let m2 = GenericMatrix([[Double(1)], [Double(2)]])
print(m2)

let m3 = m1 * m0
print(m3)

let m4 = m1 ⊗ m0
print(m4)

let m5 = m0 + m0
print(m5)

let m6 = m2 ⊗ m0
print(m6)

let m7: GenericMatrix = GenericMatrix([[Double(1), Double(2)],])
print(m7)

// Note that "Int" arguments are converted to Double!

let m8 = GenericMatrix([[5, 2]])
print(m8)

let m9 = [[1, 3], [5, 7]]
print(m9)

//: [Next](@next)
