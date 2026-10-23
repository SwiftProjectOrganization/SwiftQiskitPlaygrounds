//: [Previous](@previous)
/*:
 # Variational Algorithms: VQE

 Finding a ground-state energy by optimization instead of diagonalization: prepare a trial
 state `|ψ(θ)⟩`, measure `E(θ) = ⟨ψ|H|ψ⟩`, let a classical optimizer pick a better θ, repeat.

 - The target is the H₂ qubit Hamiltonian: six Pauli terms with weights
   `g = (-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910)`.
 - The ansatz is `x(0); ry(θ, 1); cx(1, 0)`, which gives `cos(θ/2)|10⟩ + sin(θ/2)|01⟩`.
 - The ansatz never leaves the `{|01⟩, |10⟩}` block, so a 2 × 2 closed form gives the exact
   ground energy to grade the optimizer against.
 - The parameter-shift rule `[E(θ + π/2) − E(θ − π/2)] / 2` is an exact gradient.
 - Gradient descent with a fixed learning rate of 1 converges in about ten steps.

 Limit: the energy here is the exact expectation value off the simulator. A real device
 measures each Pauli term with `measure(shots:)` and adds shot noise on top.

 Follows Chapter 23 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

// ------------------------------------------------------------
// §1 — The H₂ Hamiltonian
// ------------------------------------------------------------

let g: [Double] = [-0.4804, 0.3435, -0.4347, 0.5716, 0.0910, 0.0910]
let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix

let H = (I2 ⊗ I2) * g[0] + (Z ⊗ I2) * g[1] + (I2 ⊗ Z) * g[2] + (Z ⊗ Z) * g[3]
    + (Y ⊗ Y) * g[4] + (X ⊗ X) * g[5]
// X⊗X and Y⊗Y only connect |00⟩↔|11⟩ and |01⟩↔|10⟩: H is block-diagonal

// ------------------------------------------------------------
// §2 — A one-parameter ansatz
// ------------------------------------------------------------

func ansatz(_ theta: Double) -> StateVector {
    let qc = QuantumCircuit(qubits: 2)
    qc.x(0); qc.ry(theta, 1); qc.cx(1, 0)
    return qc.run()
}

let testPsi = ansatz(0.9)
print("ansatz(0.9): |00⟩=\(fmt(testPsi[0].magnitude))  |01⟩=\(fmt(testPsi[1].magnitude))  |10⟩=\(fmt(testPsi[2].magnitude))  |11⟩=\(fmt(testPsi[3].magnitude))")
// sin(0.45) = 0.434966 on |01⟩, cos(0.45) = 0.900447 on |10⟩, zero elsewhere

// ------------------------------------------------------------
// §3 — The energy landscape
// ------------------------------------------------------------

func energy(_ theta: Double) -> Double {
    let psi = ansatz(theta)
    return (psi† * H * psi).real
}

print("\nθ        E(θ)")
for theta in [0.0, Double.pi / 2, Double.pi, 3 * Double.pi / 2] {
    print("\(fmt(theta))  \(fmt(energy(theta)))")
}

// The ansatz stays in the {|01⟩, |10⟩} block, so its 2 × 2 eigenvalue is the exact answer:
// (a + d)/2 ± √(((a − d)/2)² + |b|²).
let a = H[1, 1].real
let d = H[2, 2].real
let bMagSq = H[1, 2].magnitudeSquared
let mean = (a + d) / 2
let discriminant = ((a - d) / 2) * ((a - d) / 2) + bMagSq
let groundEnergy = mean - discriminant.squareRoot()
let nuclearRepulsion = 0.7055
print("\nexact electronic ground energy = \(fmt(groundEnergy)) Ha")
print("total with nuclear repulsion   = \(fmt(groundEnergy + nuclearRepulsion)) Ha")
// −1.851199 and −1.145699

// ------------------------------------------------------------
// §4 — Exact gradients via the parameter-shift rule
// ------------------------------------------------------------

func parameterShiftGradient(_ theta: Double) -> Double {
    (energy(theta + .pi / 2) - energy(theta - .pi / 2)) / 2
}

func finiteDifferenceGradient(_ theta: Double, h: Double = 1e-5) -> Double {
    (energy(theta + h) - energy(theta - h)) / (2 * h)
}

print("\nθ      param-shift    finite-diff")
for theta in [0.0, 0.4, 1.0, 2.5] {
    print("\(fmt(theta))  \(fmt(parameterShiftGradient(theta)))     \(fmt(finiteDifferenceGradient(theta)))")
}
// agree to six decimals; parameter-shift needs no tiny step, so it survives shot noise

// ------------------------------------------------------------
// §5 — Gradient descent
// ------------------------------------------------------------

var theta = 0.0
let learningRate = 1.0
var visited: [(theta: Double, energy: Double)] = [(theta, energy(theta))]

print("\nstep   θ           E(θ)")
for step in 1...40 {
    theta -= learningRate * parameterShiftGradient(theta)
    visited.append((theta, energy(theta)))
    if [1, 10, 20, 30, 40].contains(step) {
        print("\(step)      \(fmt(theta))   \(fmt(energy(theta)))")
    }
}
print("\nconverged: θ = \(fmt(theta)), E = \(fmt(energy(theta)))")
print("error vs. exact = \(String(format: "%.2e", abs(energy(theta) - groundEnergy)))")
// θ = −0.229744, E = −1.851199: the exact ground energy by about step 10

// ------------------------------------------------------------
// §6 — Where the optimum sits, as a state
// ------------------------------------------------------------

let ground = ansatz(theta)
print("\nground state: |01⟩ amplitude \(fmt(ground[1].magnitude)), |10⟩ amplitude \(fmt(ground[2].magnitude))")
// about 0.1148 and 0.9934: close to the uncorrelated |10⟩ with a small |01⟩ admixture

// ------------------------------------------------------------
// §7 — Live view
// ------------------------------------------------------------
// The blue E(θ) curve over one period, with orange dots at the points descent visited.

let curve = (0...120).map { i -> CGPoint in
    let t = -Double.pi + 2 * Double.pi * Double(i) / 120
    return CGPoint(x: t, y: energy(t))
}
let path = visited.map { CGPoint(x: $0.theta, y: $0.energy) }

PlaygroundPage.current.setLiveView(
    CHSHChartView(
        title: "VQE for H₂: E(θ) and the gradient-descent path",
        xRange: -Double.pi...Double.pi,
        yRange: -2.0...0.0,
        series: [
            CHSHChartView.Series(label: "E(θ)", color: .blue, points: curve, isLine: true),
            CHSHChartView.Series(label: "descent steps", color: .orange, points: path, isLine: false)
        ]
    )
    .padding()
)

//: [Next](@next)
