//: [Previous](@previous)

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — Matrices examples
// ------------------------------------------------------------

let m0 = Matrix([[Complex(1), Complex(2)], [Complex(3), Complex(4)]])
print(m0)

let m1 = Matrix([[Complex(1), Complex(2)]])
print(m1)

let m2 = Matrix([[Complex(1)], [Complex(2)]])
print(m2)

let m3 = m1 * m0
print(m3)

let m4 = m1 ⊗ m0
print(m4)

let m5 = m0 + m0
print(m5)

let m6 = m2 ⊗ m0
print(m6)


//: [Next](@next)
