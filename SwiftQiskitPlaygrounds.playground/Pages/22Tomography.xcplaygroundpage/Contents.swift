//: [Previous](@previous)
/*:
 # State Tomography

 Reconstructing an unknown state from measurement counts alone, the way a real device
 would: it only ever reports a Z-basis `0` or `1`.

 - Rotate the axis you want into Z, then measure: X is `h`, Y is `sdg; h`, Z is nothing.
 - Estimator: `⟨A⟩ ≈ (N₀ − N₁) / N`, checked against the exact `ψ† A ψ`.
 - Error shrinks only as 1/√N: ten times the shots buys about three times the accuracy.
 - A reconstructed `(x, y, z)` lands outside the Bloch ball about half the time for a pure
   state, however large N is, because the three readings are independent and noisy.
 - A Bell pair's qubit-0 marginal, estimated from shots, comes out at the origin.
 - Full tomography needs 3ⁿ settings, which is why VQE (Chapter 23) measures only the
   Pauli terms it needs.

 Limit: the estimate is statistical and so are the sweeps; reruns land near, not on, the
 printed values. The sweeps here use fewer trials than the SwiftQiskitApp chapter so the
 page runs quickly.

 Follows Chapter 22 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

let H = HadamardGate.matrix
let Sdg = SDaggerGate.matrix
let X = PauliXGate.matrix
let Y = PauliYGate.matrix
let Z = PauliZGate.matrix
let I2 = Matrix.identity(size: 2)

// ------------------------------------------------------------
// §1 — Measuring in X, Y, and Z bases
// ------------------------------------------------------------

func basisRotation(_ axis: String, _ s: inout StateVector) {
    switch axis {
    case "X": s.apply(H)
    case "Y": s.apply(Sdg); s.apply(H)
    default: break
    }
}

var plusI = StateVector.plusI
basisRotation("Y", &plusI)
print("|+i⟩ rotated by (Sdg; H):", plusI)
// |0⟩ ≈ 1, |1⟩ ≈ 0 — the Y eigenstate collapses to |0⟩

var wrongOrder = StateVector.plusI
wrongOrder.apply(H); wrongOrder.apply(Sdg)
print("|+i⟩ rotated by (H; Sdg), wrong order:", wrongOrder)
// an equal superposition: useless for reading a bit

let rxCircuit = QuantumCircuit(qubits: 1)
rxCircuit.h(0); rxCircuit.s(0)    // |+i⟩
rxCircuit.rx(Double.pi / 2, 0)
print("|+i⟩ rotated by rx(π/2):", rxCircuit.run())
// the single-tile alternative gives the same collapse

// ------------------------------------------------------------
// §2 — Reconstructing the Bloch vector
// ------------------------------------------------------------

func tiltedState() -> StateVector {
    var s = StateVector.zero
    s.apply(RYGate.matrix(theta: 1.0472))
    s.apply(RZGate.matrix(theta: 0.7854))
    return s
}

func exactExpectation(_ psi: StateVector, _ A: Matrix) -> Double { (psi† * A * psi).real }

func estimate(_ axis: String, psi: StateVector, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots {
        var s = psi
        basisRotation(axis, &s)
        if s.measure() == 0 { plus += 1 }
    }
    return 2 * Double(plus) / Double(shots) - 1
}

let psi = tiltedState()
print("\nexact    ⟨X⟩=\(fmt(exactExpectation(psi, X)))  ⟨Y⟩=\(fmt(exactExpectation(psi, Y)))  ⟨Z⟩=\(fmt(exactExpectation(psi, Z)))")
let shots2 = 20_000
let reconstructed = (
    x: estimate("X", psi: psi, shots: shots2),
    y: estimate("Y", psi: psi, shots: shots2),
    z: estimate("Z", psi: psi, shots: shots2)
)
print("N=\(shots2) ⟨X⟩=\(fmt(reconstructed.x))  ⟨Y⟩=\(fmt(reconstructed.y))  ⟨Z⟩=\(fmt(reconstructed.z))")
// within about 0.01 of the exact values (statistical)

// ------------------------------------------------------------
// §3 — Error scaling as 1/√N
// ------------------------------------------------------------

func rmsError(_ axis: String, exact: Double, psi: StateVector, shots: Int, trials: Int) -> Double {
    let errors = (0..<trials).map { _ in estimate(axis, psi: psi, shots: shots) - exact }
    return (errors.map { $0 * $0 }.reduce(0, +) / Double(trials)).squareRoot()
}

let exactX = exactExpectation(psi, X)
print("\nN         RMS error in ⟨X⟩ (20 trials)")
for n in [100, 1_000, 10_000] {
    print("\(n)     \(fmt(rmsError("X", exact: exactX, psi: psi, shots: n, trials: 20)))")
}
// each tenfold increase in N cuts the error by about √10 ≈ 3.2

// ------------------------------------------------------------
// §4 — Why reconstruction is "unphysical" about half the time
// ------------------------------------------------------------

func reconstructedMagnitude(_ psi: StateVector, shots: Int) -> Double {
    let ex = estimate("X", psi: psi, shots: shots)
    let ey = estimate("Y", psi: psi, shots: shots)
    let ez = estimate("Z", psi: psi, shots: shots)
    return (ex * ex + ey * ey + ez * ez).squareRoot()
}

func unphysicalFrequency(_ psi: StateVector, shots: Int, trials: Int) -> Double {
    let hits = (0..<trials).filter { _ in reconstructedMagnitude(psi, shots: shots) > 1.0 }.count
    return Double(hits) / Double(trials)
}

print("\nPure tilted state, unphysical (|r| > 1) frequency, 100 trials:")
for n in [10, 50, 200, 1000] {
    print("  N=\(n): \(fmt(unphysicalFrequency(psi, shots: n, trials: 100)))")
}
// plateaus near 0.5: symmetric noise straddles a boundary point

var plusState = StateVector.zero
plusState.apply(H)
print("|+⟩ edge case, 100 trials:")
for n in [10, 50, 200, 1000] {
    print("  N=\(n): \(fmt(unphysicalFrequency(plusState, shots: n, trials: 100)))")
}
// its X-estimate is exactly 1, so any Y or Z noise pushes |r| over 1

func sampleMixedAndMeasure(_ axis: String) -> Int {
    var s = Double.random(in: 0..<1) < 0.75 ? StateVector.zero : StateVector.one
    basisRotation(axis, &s)
    return s.measure()
}

func estimateMixed(_ axis: String, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots { if sampleMixedAndMeasure(axis) == 0 { plus += 1 } }
    return 2 * Double(plus) / Double(shots) - 1
}

func unphysicalFrequencyMixed(shots: Int, trials: Int) -> Double {
    var count = 0
    for _ in 0..<trials {
        let ex = estimateMixed("X", shots: shots)
        let ey = estimateMixed("Y", shots: shots)
        let ez = estimateMixed("Z", shots: shots)
        if (ex * ex + ey * ey + ez * ez).squareRoot() > 1.0 { count += 1 }
    }
    return Double(count) / Double(trials)
}

print("Mixed state (|r| = 0.5), 100 trials:")
for n in [10, 50, 200, 1000] {
    print("  N=\(n): \(fmt(unphysicalFrequencyMixed(shots: n, trials: 100)))")
}
// shrinks to 0: a mixed state sits strictly inside the ball

// ------------------------------------------------------------
// §5 — An entangled qubit's marginal, from shots alone
// ------------------------------------------------------------

var bell = StateVector(qubits: 2)
bell.apply(H.tensor(I2))
bell.apply(CNOTGate.matrix(qubits: 2, control: 0, target: 1))

func estimateQubit0(_ axis: String, state: StateVector, shots: Int) -> Double {
    var plus = 0
    for _ in 0..<shots {
        var s = state
        switch axis {
        case "X": s.apply(H.tensor(I2))
        case "Y": s.apply(Sdg.tensor(I2)); s.apply(H.tensor(I2))
        default: break
        }
        if (s.measure() >> 1) & 1 == 0 { plus += 1 }    // qubit 0 is the MSB
    }
    return 2 * Double(plus) / Double(shots) - 1
}

let bx = estimateQubit0("X", state: bell, shots: 20_000)
let by = estimateQubit0("Y", state: bell, shots: 20_000)
let bz = estimateQubit0("Z", state: bell, shots: 20_000)
print("\nBell-pair qubit-0 marginal: (x,y,z) = (\(fmt(bx)), \(fmt(by)), \(fmt(bz))), |r| = \(fmt((bx * bx + by * by + bz * bz).squareRoot()))")
// statistically the origin: one copy of an entangled qubit carries no information

// ------------------------------------------------------------
// §6 — Why full tomography doesn't scale
// ------------------------------------------------------------

print("\nqubits   settings (3ⁿ)")
for n in 1...5 { print("\(n)        \(Int(pow(3.0, Double(n))))") }

// ------------------------------------------------------------
// §7 — Live view
// ------------------------------------------------------------
// The exact tilted state, its reconstruction from shots, and the Bell marginal.
// A raw estimate can fall outside the ball, so it is rescaled onto the surface for display.
// Stateless views (no @State) — required for page code.

func clamped(_ x: Double, _ y: Double, _ z: Double) -> BlochVector {
    let r = (x * x + y * y + z * z).squareRoot()
    let scale = r > 1 ? 1 / r : 1
    return BlochVector(x: x * scale, y: y * scale, z: z * scale)
}

struct TomographyView: View {
    let exact: BlochVector
    let rebuilt: BlochVector
    let bellMarginal: BlochVector

    var body: some View {
        HStack(spacing: 8) {
            BlochSphereView(label: "exact state", bloch: exact, size: 170)
            BlochSphereView(label: "from \(shots2) shots", bloch: rebuilt, size: 170)
            BlochSphereView(label: "Bell qubit 0", bloch: bellMarginal, size: 170)
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    TomographyView(
        exact: BlochVector(x: exactExpectation(psi, X), y: exactExpectation(psi, Y), z: exactExpectation(psi, Z)),
        rebuilt: clamped(reconstructed.x, reconstructed.y, reconstructed.z),
        bellMarginal: clamped(bx, by, bz)
    )
    .frame(width: 600, height: 260)
)

//: [Next](@next)
