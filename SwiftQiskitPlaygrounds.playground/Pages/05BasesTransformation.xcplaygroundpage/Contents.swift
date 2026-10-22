//: [Previous](@previous)
/*:
 # Bases transformations
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews


// ------------------------------------------------------------
// §1 — Basis transformations (preview of 41BasisTransformations §1–4)
// ------------------------------------------------------------

// Given |ψ⟩ in the computational basis {|0⟩, |1⟩}, what are its coordinates in a
// different basis, e.g. {|+⟩, |−⟩}? Stack the new basis kets as the columns of T, so
// |ψ⟩ = T·c; since T is unitary, c = T⁻¹|ψ⟩ = T†|ψ⟩,
// the library's own `†` (Matrix.adjoint) already is T⁻¹ for a unitary T.

let psi: Ket = .zero
// want c₊, c₋ such that |ψ⟩ = c₊|+⟩ + c₋|−⟩

let T = Matrix((0..<2).map { row in [Ket.plus[row], Ket.minus[row]] })
let Tdag = T†

let c = Tdag.multiply(by: psi.amplitudes)
// [0.7071067811865475, 0.7071067811865475]

Ket.plus† * psi
// = c[0] — row j of T† times ψ is literally the inner product ⟨bⱼ|ψ⟩
Ket.minus† * psi
// = c[1]

c.map { $0.magnitudeSquared }
// [0.5, 0.5] — |0⟩ is certain in Z, an even split in ±

Tdag.multiply(by: Ket.plus.amplitudes)
// [1, 0] — |+⟩ is certain in its own basis

Tdag.multiply(by: Ket.plusI.amplitudes)
// an even split again — |+i⟩ is as undetermined in ± as |0⟩ is

let ket1 = Ket([Complex(0.8), Complex(0.4243, 0.4243)])

// ------------------------------------------------------------
// §2 — Basis transformations on ket1
// ------------------------------------------------------------

// Same machinery on ket1, which isn't a Z eigenstate either:
let c1 = Tdag.multiply(by: ket1.amplitudes)
c1.map { $0.magnitudeSquared }
// vs. ket1's own Z-basis probabilities [0.75, 0.25] — a different basis, a different
// distribution

// A complex basis {|+i⟩, |−i⟩}: same column-mapping/T† recipe, no hand-built rows of bras.
let T2 = Matrix((0..<2).map { row in [Ket.plusI[row], Ket.minusI[row]] })
let Tdag2 = T2†

Tdag2.multiply(by: Ket.plusI.amplitudes)

// [1, 0] — |+i⟩ is certain once expressed in its own basis

// See 41BasisTransformations for why T† (not a plain transpose) is required here, and
// how to measure directly in a new basis.

//: [Next](@next)
