//: [Previous](@previous)
/*:
 # Hamiltonian Simulation and Trotter Error

 Simulating time evolution `U(t) = e^(−iHt)` of a 2-qubit transverse-field Ising chain
 by chopping it into gates.

 - `H = −J·Z⊗Z − h·(X⊗I + I⊗X)` with `J = 1.0`, `h = 0.5`.
 - `Matrix.expm()` (a scaling-and-squaring Taylor series) serves as ground truth, itself
   checked against the exact `RXGate`. It has no implicit −i, so e^(−iHt) is
   `(H * Complex(0, -t)).expm()`.
 - `exp(−iθ·Z⊗Z/2)` is exactly `cx(0,1); rz(θ,1); cx(0,1)`.
 - First-order Trotter error shrinks as 1/n; the second-order (Suzuki) split shrinks as 1/n².
 - The error exists because `Z⊗Z` and `X⊗I` do not commute: with `h = 0` one step is exact.
 - A fixed step count drifts at larger t, since the error depends on `dt = t/n`.
 - One full Trotter step is `cx`, `rz`, `cx`, `rx`, `rx`, so the circuit form matches the
   matrix form.

 Limit: `expm` builds dense 2ⁿ × 2ⁿ matrices, so the matrix side only scales to a few qubits.

 Follows Chapter 24 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

func maxDiff(_ a: Matrix, _ b: Matrix) -> Double {
    var m = 0.0
    for i in 0..<a.rows { for j in 0..<a.cols { m = max(m, (a[i, j] - b[i, j]).magnitude) } }
    return m
}

let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix
let Z = PauliZGate.matrix
let ZZ = Z ⊗ Z

// ------------------------------------------------------------
// §1 — The spin-chain Hamiltonian
// ------------------------------------------------------------

let J = 1.0, h = 0.5
let Hising = (ZZ * (-J)) + (X ⊗ I2) * (-h) + (I2 ⊗ X) * (-h)

// ------------------------------------------------------------
// §2 — An expm ground truth
// ------------------------------------------------------------

let theta = 0.7
let expmRX = (X * Complex(0, -theta / 2)).expm()
print("expm(-iθX/2) vs. RXGate.matrix(θ=0.7): max diff = \(String(format: "%.2e", maxDiff(expmRX, RXGate.matrix(theta: theta))))")
// about 1e-16: expm is trustworthy

// ------------------------------------------------------------
// §3 — ZZ(θ) as an exact gate identity
// ------------------------------------------------------------

func zzViaGates(_ theta: Double) -> Matrix {
    let cx = CNOTGate.matrix(qubits: 2, control: 0, target: 1)
    let rz1 = I2 ⊗ RZGate.matrix(theta: theta)
    return cx * rz1 * cx
}

let expmZZ = (ZZ * Complex(0, -theta / 2)).expm()
print("expm(-iθZ⊗Z/2) vs. cx;rz;cx (θ=0.7): max diff = \(String(format: "%.2e", maxDiff(expmZZ, zzViaGates(theta))))")
// about 1e-16: an exact identity, not an approximation

// ------------------------------------------------------------
// §4 — Trotter error shrinking as 1/n, and §5 — Suzuki's 1/n²
// ------------------------------------------------------------

func trotterUnitary(_ t: Double, _ n: Int, order: Int) -> Matrix {
    let dt = t / Double(n)
    let uZZ = zzViaGates(-2 * J * dt)
    let rxQ0 = RXGate.matrix(theta: -2 * h * dt) ⊗ I2
    let rxQ1 = I2 ⊗ RXGate.matrix(theta: -2 * h * dt)
    let step: Matrix
    if order == 1 {
        step = rxQ1 * rxQ0 * uZZ
    } else {
        let uZZhalf = zzViaGates(-2 * J * (dt / 2))
        step = uZZhalf * rxQ1 * rxQ0 * uZZhalf    // half-ZZ on each side
    }
    var result = Matrix.identity(size: 4)
    for _ in 0..<n { result = step * result }
    return result
}

let t = 1.0
let exact = (Hising * Complex(0, -t)).expm()

for (title, order) in [("1st-order Trotter error (max diff from exact), t=1:", 1),
                       ("2nd-order (Suzuki) Trotter error:", 2)] {
    print("\n" + title)
    var previous = 0.0
    for n in [1, 2, 4, 8, 16, 32] {
        let err = maxDiff(exact, trotterUnitary(t, n, order: order))
        print("  n=\(n)   \(fmt(err))" + (n == 1 ? "" : "   ratio = \(fmt(err / previous))"))
        previous = err
    }
}
// ratios converge to 0.5 (first order) and 0.25 (second order)

// ------------------------------------------------------------
// §6 — Why non-commuting terms cause the error
// ------------------------------------------------------------

let X0 = X ⊗ I2
let commutator = (ZZ * X0) + (X0 * ZZ) * (-1.0)
var commNorm = 0.0
for i in 0..<4 { for j in 0..<4 { commNorm = max(commNorm, commutator[i, j].magnitude) } }
print("\nmax |[Z⊗Z, X⊗I]| entry: \(fmt(commNorm))")    // 2.000000

let exactComm = ((ZZ * (-J)) * Complex(0, -t)).expm()
print("commuting-only Hamiltonian (h=0), n=1 error: \(String(format: "%.2e", maxDiff(exactComm, zzViaGates(-2 * J * t))))")
// 0: with one term there is nothing to split

func expectationZ0(_ state: StateVector) -> Double { (state† * (Z ⊗ I2) * state).real }
let psi0 = StateVector(qubits: 2)

func zExpectation(_ tVal: Double, n: Int?) -> Double {
    var s = psi0
    s.apply(n.map { trotterUnitary(tVal, $0, order: 1) } ?? (Hising * Complex(0, -tVal)).expm())
    return expectationZ0(s)
}

print("\n⟨Z₀⟩(t): exact vs. Trotterized n=2, n=8")
print("t       exact       n=2         n=8")
for tVal in [0.5, 1.0, 1.5, 2.0, 2.5, 3.0] {
    print("\(fmt(tVal))   \(fmt(zExpectation(tVal, n: nil)))    \(fmt(zExpectation(tVal, n: 2)))    \(fmt(zExpectation(tVal, n: 8)))")
}
// n=8 tracks the exact curve; n=2 drifts badly by t = 2.5–3.0

// ------------------------------------------------------------
// §7 — The same step as a circuit
// ------------------------------------------------------------
// One first-order step at t = 1, n = 2 (dt = 0.5): ZZ angle −2·J·dt, RX angle −2·h·dt.

let dt = t / 2
let circuit = QuantumCircuit(qubits: 2)
for _ in 0..<2 {
    circuit.cx(0, 1); circuit.rz(-2 * J * dt, 1); circuit.cx(0, 1)
    circuit.rx(-2 * h * dt, 0); circuit.rx(-2 * h * dt, 1)
}
let circuitState = circuit.run()
var matrixState = psi0
matrixState.apply(trotterUnitary(t, 2, order: 1))
print("\ncircuit ⟨Z₀⟩ = \(fmt(expectationZ0(circuitState))), matrix ⟨Z₀⟩ = \(fmt(expectationZ0(matrixState)))")
print("max amplitude diff: \(String(format: "%.2e", (0..<4).map { (circuitState[$0] - matrixState[$0]).magnitude }.max() ?? 0))")
// 0.645963 both ways, equal to floating-point noise

// ------------------------------------------------------------
// §8 — Live view
// ------------------------------------------------------------
// ⟨Z₀⟩(t) for the exact evolution and two Trotter step counts.

func series(_ label: String, color: Color, n: Int?) -> CHSHChartView.Series {
    let points = (0...30).map { i -> CGPoint in
        let tVal = 3.0 * Double(i) / 30
        return CGPoint(x: tVal, y: zExpectation(tVal, n: n))
    }
    return CHSHChartView.Series(label: label, color: color, points: points, isLine: true)
}

PlaygroundPage.current.setLiveView(
    CHSHChartView(
        title: "⟨Z₀⟩(t): exact vs. first-order Trotter",
        xRange: 0...3.0,
        yRange: 0...1.1,
        series: [
            series("exact", color: .blue, n: nil),
            series("n = 8", color: .green, n: 8),
            series("n = 2", color: .red, n: 2)
        ]
    )
    .padding()
)

//: [Next](@next)
