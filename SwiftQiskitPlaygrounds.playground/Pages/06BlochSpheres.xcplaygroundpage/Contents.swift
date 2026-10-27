//: [Previous](@previous)
/*:
 # The Bloch sphere in 2D and 3D

 A qubit `|ψ⟩ = α|0⟩ + β|1⟩` has four real numbers in its amplitudes, but normalization and
 the unobservable global phase remove two of them. The two that remain fit on a sphere: the
 point `(x, y, z) = (2·Re(ᾱβ), 2·Im(ᾱβ), |α|² − |β|²)`, the same three Pauli expectation
 values `04Dirac` computed as bra–ket sandwiches.

 This page places the six canonical states on the sphere, builds a general tilted state,
 shows what the 2D plane projections drop, and then derives the spherical parametrization
 `|ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩`. θ alone sets the measurement statistics; φ is
 invisible to a Z-basis measurement. The live view shows the 2D gallery, the projections,
 a draggable 3D sphere and a θ/φ slider explorer.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// ------------------------------------------------------------
// §1 — The six canonical states on the sphere
// ------------------------------------------------------------

let zero = QuantumCircuit(qubits: 1)
let one = QuantumCircuit(qubits: 1); one.x(0)
let plus = QuantumCircuit(qubits: 1); plus.h(0)
let minus = QuantumCircuit(qubits: 1); minus.h(0); minus.z(0)
let plusI = QuantumCircuit(qubits: 1); plusI.h(0); plusI.s(0)
let minusI = QuantumCircuit(qubits: 1); minusI.h(0); minusI.sdg(0)

let canonical: [(name: String, bloch: BlochVector)] = [
    ("|0⟩", BlochVector(zero.run())),
    ("|1⟩", BlochVector(one.run())),
    ("|+⟩", BlochVector(plus.run())),
    ("|−⟩", BlochVector(minus.run())),
    ("|+i⟩", BlochVector(plusI.run())),
    ("|−i⟩", BlochVector(minusI.run()))
]

for s in canonical {
    let b = s.bloch
    print(String(format: "%@  x %+.3f  y %+.3f  z %+.3f  (θ %.3f, φ %.3f)",
                 s.name, b.x, b.y, b.z, b.theta, b.phi))
}
// |0⟩  x +0.000  y +0.000  z +1.000  (θ 0.000, φ 0.000)   north pole
// |1⟩  x +0.000  y +0.000  z -1.000  (θ 3.142, φ 0.000)   south pole
// |+⟩  x +1.000  y +0.000  z +0.000  (θ 1.571, φ 0.000)   +x axis
// |−⟩  x -1.000  y +0.000  z +0.000  (θ 1.571, φ 3.142)   −x axis
// |+i⟩  x +0.000  y +1.000  z +0.000  (θ 1.571, φ 1.571)  +y axis
// |−i⟩  x +0.000  y -1.000  z +0.000  (θ 1.571, φ -1.571) −y axis
//
// θ = acos(z) is the polar angle from |0⟩, φ = atan2(y, x) the azimuth. φ = 0 at the poles
// is a convention (atan2(0, 0) = 0), not information. The ±1s carry ~1e-16 rounding.

// ------------------------------------------------------------
// §2 — Global phase is invisible on the sphere
// ------------------------------------------------------------
// Multiplying both amplitudes by e^{iγ} leaves ᾱβ, |α|² and |β|² unchanged, so the
// Bloch point does not move.

let gamma = 0.7
let phase = Complex(argument: gamma)
let plusState = plus.run()
let plusPhased = StateVector(plusState.amplitudes.map { phase * $0 })
let b1 = BlochVector(plusState), b2 = BlochVector(plusPhased)
print("global phase Δ:", abs(b1.x - b2.x), abs(b1.y - b2.y), abs(b1.z - b2.z))
// global phase Δ: 0.0 0.0 0.0

// Z and RZ(π) differ only by a global phase, so H·Z and H·RZ(π) both land on |−⟩.
let viaRZ = QuantumCircuit(qubits: 1); viaRZ.h(0); viaRZ.rz(.pi, 0)
let bRZ = BlochVector(viaRZ.run())
print(String(format: "h; rz(π)  x %+.3f  y %+.3f  z %+.3f", bRZ.x, bRZ.y, bRZ.z))
// h; rz(π)  x -1.000  y +0.000  z +0.000 — the same point as h; z

// ------------------------------------------------------------
// §3 — A general tilted state
// ------------------------------------------------------------
// A unit vector at 45° from the x-axis and 60° from the y-axis. Its components are the
// direction cosines: x = cos 45° ≈ 0.7071, y = cos 60° = 0.5, z = √(1 − x² − y²) = 0.5.
// That gives θ = acos(z) = 60° and φ = atan2(y, x) ≈ 35.264°.

let tiltTheta = Double.pi / 3
let tiltPhi = atan2(0.5, sqrt(2) / 2)

let tilted = StateVector([
    Complex(cos(tiltTheta / 2)),
    Complex(magnitude: sin(tiltTheta / 2), argument: tiltPhi)
])
let tiltBloch = BlochVector(tilted)
print(tiltBloch.x, tiltBloch.y, tiltBloch.z)
// 0.7071067811865475 0.4999999999999999 0.5000000000000002
print(acos(tiltBloch.x) * 180 / .pi, acos(tiltBloch.y) * 180 / .pi, acos(tiltBloch.z) * 180 / .pi)
// ≈ 45.0 60.0 60.0 — the direction cosines recovered

// The same state from gates: RY(θ) tilts away from |0⟩, P(φ) then turns the azimuth.
let tiltCircuit = QuantumCircuit(qubits: 1)
tiltCircuit.ry(tiltTheta, 0)
tiltCircuit.p(tiltPhi, 0)
let tiltFromGates = tiltCircuit.run()
print(tiltFromGates.amplitudes, tiltFromGates.probabilities)
// [0.866…, 0.408… + 0.288…i] [0.75, 0.25]
let tiltGateBloch = BlochVector(tiltFromGates)
print(tiltGateBloch.x, tiltGateBloch.y, tiltGateBloch.z, tiltGateBloch.theta, tiltGateBloch.phi)
// 0.7071… 0.5 0.5 1.0471… 0.6154… — the same point as the amplitude construction

// ------------------------------------------------------------
// §4 — Reading a 3D sphere in 2D: two plane projections
// ------------------------------------------------------------
// An orthographic projection onto a coordinate plane drops the out-of-plane component.
// The projected arrow has length r = hypot(h, v), and r² = 1 − (dropped component)².

let rXY = hypot(tiltBloch.x, tiltBloch.y)
let rZY = hypot(tiltBloch.z, tiltBloch.y)
print(String(format: "x–y plane (from +z): r %.3f, dropped z %.3f", rXY, tiltBloch.z))
print(String(format: "z–y plane (from +x): r %.3f, dropped x %.3f", rZY, tiltBloch.x))
// x–y plane (from +z): r 0.866, dropped z 0.500
// z–y plane (from +x): r 0.707, dropped x 0.707
//
// The x–y panel looks down from the |0⟩ pole. To keep x pointing toward the viewer as on
// the main sphere, x must point *down* on that canvas, hence `verticalPointsDown: true`.
//
// `BlochSphereView` instead draws one oblique projection: y to the right, z up, and x
// foreshortened by 0.5·√0.5 ≈ 0.354 toward the lower-left. So |+⟩ draws as a short arrow.
// A short arrow is ambiguous between "points toward the viewer" and "|r| < 1" (an
// entangled qubit, 12Entanglement); the view prints |r| explicitly in the latter case.

// ------------------------------------------------------------
// §5 — The θ/φ parametrization
// ------------------------------------------------------------
// Use the global phase to make α real and non-negative: α = cos(θ/2), θ ∈ [0, π].
// Normalization then forces |β| = sin(θ/2), so β = e^{iφ}·sin(θ/2), φ ∈ [0, 2π):
//
//     |ψ⟩ = cos(θ/2)|0⟩ + e^{iφ}·sin(θ/2)|1⟩
//
// θ is the sphere angle, θ/2 appears in the amplitudes: antipodal points are orthogonal
// states. Normalization holds identically, cos²(θ/2) + |e^{iφ}|²·sin²(θ/2) = 1, so θ and
// φ are completely independent.

func makeState(theta: Double, phi: Double) -> StateVector {
    StateVector([
        Complex(cos(theta / 2)),
        Complex(magnitude: sin(theta / 2), argument: phi)
    ])
}

var sweepOK = true
for theta in stride(from: 0.0, through: Double.pi, by: Double.pi / 4) {
    for phi in stride(from: 0.0, through: 2 * Double.pi, by: Double.pi / 3) {
        let s = makeState(theta: theta, phi: phi)
        let norm = s[0].magnitudeSquared + s[1].magnitudeSquared
        if abs(norm - 1) > 1e-9 {
            print("FAIL", theta, phi, norm)
            sweepOK = false
        }
    }
}
print(sweepOK ? "sweep ok" : "sweep failed")
// sweep ok — 5 × 7 = 35 angle pairs, all normalized

let initialTheta = Double.pi / 3
let initialPhi = Double.pi / 4
let psi = makeState(theta: initialTheta, phi: initialPhi)
print(String(format: "θ = %.3f rad (%.1f°), φ = %.3f rad (%.1f°)",
             initialTheta, initialTheta * 180 / .pi, initialPhi, initialPhi * 180 / .pi))
print("α = ⟨0|ψ⟩ = \(psi[0])")
print("β = ⟨1|ψ⟩ = \(psi[1])")
// θ = 1.047 rad (60.0°), φ = 0.785 rad (45.0°)
// α = 0.8660254037844387, β = 0.35355339059327373 + 0.3535533905932737i
// The same |ψ⟩ that 04Dirac read off as Pauli expectations (0.6124, 0.6124, 0.5000).

// ------------------------------------------------------------
// §6 — θ moves the statistics, φ does not
// ------------------------------------------------------------
// P(0) = cos²(θ/2) and P(1) = sin²(θ/2) depend only on θ.

for theta in [0.0, Double.pi / 3, Double.pi / 2, 2 * Double.pi / 3] {
    let c = QuantumCircuit(qubits: 1)
    c.ry(theta, 0)
    c.p(.pi / 4, 0)
    let st = c.run()
    print(String(format: "θ %.3f  probs [%.3f, %.3f]  bloch.theta %.3f",
                 theta, st.probabilities[0], st.probabilities[1], BlochVector(st).theta))
}
// θ 0.000  probs [1.000, 0.000]  bloch.theta 0.000
// θ 1.047  probs [0.750, 0.250]  bloch.theta 1.047
// θ 1.571  probs [0.500, 0.500]  bloch.theta 1.571
// θ 2.094  probs [0.250, 0.750]  bloch.theta 2.094

// Sweeping φ at fixed θ = π/3 slides the state around its latitude. The probabilities
// never change; only bloch.phi tracks the input.
for phi in [0.0, Double.pi / 4, Double.pi / 2, Double.pi] {
    let c = QuantumCircuit(qubits: 1)
    c.ry(.pi / 3, 0)
    c.p(phi, 0)
    let st = c.run()
    print(String(format: "φ %.3f  probs [%.3f, %.3f]  bloch.phi %.3f",
                 phi, st.probabilities[0], st.probabilities[1], BlochVector(st).phi))
}
// φ 0.000  probs [0.750, 0.250]  bloch.phi 0.000
// φ 0.785  probs [0.750, 0.250]  bloch.phi 0.785
// φ 1.571  probs [0.750, 0.250]  bloch.phi 1.571
// φ 3.142  probs [0.750, 0.250]  bloch.phi 3.142
//
// φ is exactly the "hidden" information 08Interference recovers by interference.

// ------------------------------------------------------------
// §7 — Rotating the view vs rotating the state
// ------------------------------------------------------------
// `Bloch3DView` orbits a perspective camera (azimuth about z, elevation above the
// equator) around a fixed sphere. Dragging it moves the *viewer*: the x/y/z/θ/φ caption
// never changes. Looking straight down from |0⟩ reads φ as a flat protractor angle; from
// the equator θ becomes a left–right angle. This resolves §4's short-arrow ambiguity by
// looking from another angle.
//
// `BlochExplorerView`'s θ and φ sliders rebuild the state instead: that moves the arrow
// itself. Every slider position is a valid normalized state (§5).

// ------------------------------------------------------------
// Live view — 2D gallery, projections, 3D sphere and θ/φ explorer
// ------------------------------------------------------------
// Stateless view (no @State) — required for page code. The explorer keeps its slider
// state inside the library view.

struct BlochSpheresView: View {
    let canonical: [(name: String, bloch: BlochVector)]
    let tilted: BlochVector

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Six canonical states").font(.title2)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(260)), count: 3), spacing: 16) {
                    ForEach(canonical, id: \.name) { state in
                        BlochSphereView(label: state.name, bloch: state.bloch)
                    }
                }

                Text("A tilted state and its plane projections").font(.title2)
                HStack(spacing: 16) {
                    BlochSphereView(label: "θ = 60°, φ ≈ 35.3°", bloch: tilted)
                    BlochProjectionView(
                        label: "x–y plane (from +z)",
                        horizontal: ("y", tilted.y),
                        vertical: ("x", tilted.x),
                        verticalPointsDown: true
                    )
                    .frame(width: 260, height: 280)
                    BlochProjectionView(
                        label: "z–y plane (from +x)",
                        horizontal: ("y", tilted.y),
                        vertical: ("z", tilted.z)
                    )
                    .frame(width: 260, height: 280)
                }

                Text("Rotate the view (drag) vs rotate the state (sliders)").font(.title2)
                HStack(alignment: .top, spacing: 24) {
                    Bloch3DView(label: "drag to orbit", bloch: tilted)
                    BlochExplorerView()
                }
            }
            .padding()
        }
    }
}

PlaygroundPage.current.setLiveView(
    BlochSpheresView(canonical: canonical, tilted: tiltBloch)
        .frame(width: 840, height: 1100)
)

//: [Next](@next)
