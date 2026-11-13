//: [Previous](@previous)
/*:
 # The geometry of quantum states

 A relative phase changes where an interferometer sends its photons, even when the two path
 populations stay equal. This page follows that observation through the geometry of a qubit.
 ℏ = 1 throughout.

 The article: [The Geometry of Quantum States](https://thequantasticjournal.com/the-geometry-of-quantum-states-4844ecc5e300)
 by Sam Vaseghi, The Quantastic Journal (Medium), November 2026.

 - **Phase.** `|ψ(φ)⟩ = (|0⟩ + e^{iφ}|1⟩)/√2` has path probabilities ½, ½ for every φ. After
   a balanced recombiner (a Hadamard) the ports have probabilities cos²(φ/2) and sin²(φ/2).
   An overall phase changes neither.
 - **Rays.** Vectors that differ by an overall phase are one physical state. The
   representative with a real, non-negative `|0⟩` coefficient gives θ and φ, the Bloch sphere
   coordinates.
 - **Distance.** `D(ψ, φ) = arccos |⟨φ|ψ⟩|` (the Fubini–Study distance). Orthogonal states are
   π/2 apart, half the Bloch angle. The line element is `ds² = ⟨dψ|dψ⟩ − |⟨ψ|dψ⟩|²`.
 - **Motion.** For `H = (ω/2)Z` the state moves along a latitude with speed `ΔH = (ω/2) sin θ`.
   Reaching an orthogonal state takes at least `π/(2ΔH)`.
 - **Geometric phase.** A loop on the sphere that encloses solid angle Ω leaves the phase
   `−Ω/2`. The page computes it as a product of overlaps around the loop.
 - **Larger systems.** A marker qubit that records the path reduces the fringe contrast to
   `|⟨A₀|A₁⟩|`. A pure two-qubit state can have a mixed reduced state, a point inside the ball.
 - **Records.** A measurement is a set of effects `Eₐ` with `p(a) = Tr(ρEₐ)`.

 Not covered: article section 7 (Poincaré symmetry, mass) has no qubit calculation, and the
 page does not model decoherence or the single outcome of one run.

 Limit: the line element and the geometric phase are finite sums over small steps, so they
 agree with the closed forms to about 1e-3 rather than to machine precision.

 Follows "The Geometry of Quantum States" by Sam Vaseghi (The Quantastic Journal, November 2026).
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func fmt(_ d: Double) -> String { String(format: "%.6f", d) }

let I2 = Matrix.identity(size: 2)
let X = PauliXGate.matrix
let Z = PauliZGate.matrix
let H = HadamardGate.matrix

/// cos(θ/2)|0⟩ + e^{iφ} sin(θ/2)|1⟩
func ket(_ theta: Double, _ phi: Double) -> Ket {
    Ket([Complex(cos(theta / 2)), Complex(argument: phi) * sin(theta / 2)])
}

/// |⟨a|b⟩|, which survives the passage to rays.
func overlap(_ a: Ket, _ b: Ket) -> Double { (a† * b).magnitude }

/// Fubini–Study distance arccos |⟨a|b⟩|.
func distance(_ a: Ket, _ b: Ket) -> Double { acos(min(1, overlap(a, b))) }

/// ds between two nearby normalized vectors: sqrt(⟨dψ|dψ⟩ − |⟨ψ|dψ⟩|²).
func lineElement(_ a: Ket, _ b: Ket) -> Double {
    var norm = 0.0
    var parallel = Complex.zero
    for i in 0..<a.amplitudes.count {
        let d = b.amplitudes[i] - a.amplitudes[i]
        norm += d.magnitudeSquared
        parallel = parallel + a.amplitudes[i].conjugate * d
    }
    return max(0, norm - parallel.magnitudeSquared).squareRoot()
}

/// Multiplies every amplitude by e^{iχ}.
func withGlobalPhase(_ psi: Ket, _ chi: Double) -> Ket {
    Ket(psi.amplitudes.map { $0 * Complex(argument: chi) })
}

// ------------------------------------------------------------
// §1 — A phase that changes the destination
// ------------------------------------------------------------

print("§1  φ        path P(0),P(1)      port P(+)   cos²(φ/2)   port P(−)   sin²(φ/2)")
for phi in [0.0, Double.pi / 2, Double.pi, 3 * Double.pi / 2] {
    let psi = Ket([.one, Complex(argument: phi)])
    var out = psi
    out.apply(H)
    let paths = psi.probabilities
    print("    \(fmt(phi))   \(fmt(paths[0])), \(fmt(paths[1]))   \(fmt(out.probabilities[0]))    \(fmt(pow(cos(phi / 2), 2)))    \(fmt(out.probabilities[1]))    \(fmt(pow(sin(phi / 2), 2)))")
}

// An overall phase changes neither port; a phase on one term moves the probability.
let base = Ket([.one, Complex(argument: Double.pi / 3)])
var globallyShifted = withGlobalPhase(base, 1.1)
globallyShifted.apply(H)
var baseOut = base
baseOut.apply(H)
var oneTermShifted = Ket([.one, Complex(argument: Double.pi / 3 + 1.1)])
oneTermShifted.apply(H)
print("    P(+): base \(fmt(baseOut.probabilities[0])), overall phase \(fmt(globallyShifted.probabilities[0])), phase on one term \(fmt(oneTermShifted.probabilities[0]))")

// ------------------------------------------------------------
// §2 — Rays and the Bloch sphere
// ------------------------------------------------------------

let vector = Ket([Complex(0.6, 0.3), Complex(-0.2, 0.7)])
let a0 = vector.amplitudes[0]
let a1 = vector.amplitudes[1]
// Choose the representative whose |0⟩ coefficient is real and non-negative.
let thetaRay = 2 * acos(min(1, a0.magnitude))
let phiRay = a1.argument - a0.argument
let blochA = BlochVector(vector)
let blochB = BlochVector(withGlobalPhase(vector, 2.4))
print("\n§2  θ from amplitudes \(fmt(thetaRay)), from BlochVector \(fmt(blochA.theta))")
print("    φ from amplitudes \(fmt(phiRay)), from BlochVector \(fmt(blochA.phi))")
print("    Bloch vector, vector:        (\(fmt(blochA.x)), \(fmt(blochA.y)), \(fmt(blochA.z)))")
print("    Bloch vector, e^{2.4i}·vector: (\(fmt(blochB.x)), \(fmt(blochB.y)), \(fmt(blochB.z)))")
for n in [2, 4, 8] {
    print("    n = \(n) basis states: \(2 * n - 1) real parameters, \(2 * n - 2) after removing the overall phase")
}

// ------------------------------------------------------------
// §3 — Distance between possibilities
// ------------------------------------------------------------

print("\n§3  φ        D(ψ(φ), |+⟩)   φ/2        P(+) = cos²D   Born P(+)")
for phi in [0.0, Double.pi / 2, Double.pi] {
    let psi = ket(Double.pi / 2, phi)
    let d = distance(psi, Ket.plus)
    print("    \(fmt(phi))   \(fmt(d))       \(fmt(phi / 2))   \(fmt(pow(cos(d), 2)))       \(fmt(pow(overlap(Ket.plus, psi), 2)))")
}
print("    orthogonal |0⟩, |1⟩: D = \(fmt(distance(Ket.zero, Ket.one))), π/2 = \(fmt(Double.pi / 2))")

// Length of one full turn around the equator, from the line element.
let steps = 1000
var pathLength = 0.0
var previous = ket(Double.pi / 2, 0)
for k in 1...steps {
    let next = ket(Double.pi / 2, 2 * Double.pi * Double(k) / Double(steps))
    pathLength += lineElement(previous, next)
    previous = next
}
print("    equator loop: length \(fmt(pathLength)) (π = \(fmt(Double.pi))), endpoint distance \(fmt(distance(ket(Double.pi / 2, 0), previous)))")
let sameRay = withGlobalPhase(Ket.plus, 0.01)
print("    pure phase change: ds = \(String(format: "%.2e", lineElement(Ket.plus, sameRay)))")

// ------------------------------------------------------------
// §4 — How a state moves
// ------------------------------------------------------------

let omega = 2.0
let hamiltonian = Z * (omega / 2)
let hSquared = hamiltonian * hamiltonian

func evolve(_ psi: Ket, _ h: Matrix, time: Double) -> Ket {
    var out = psi
    out.apply((h * Complex(0, -time)).expm())
    return out
}

print("\n§4  θ        speed (finite diff)   ΔH = (ω/2) sin θ   ΔH from ⟨H²⟩ − ⟨H⟩²")
let dt = 1e-4
for theta in [0.0, Double.pi / 6, Double.pi / 3, Double.pi / 2] {
    let psi = ket(theta, 0)
    let speed = lineElement(psi, evolve(psi, hamiltonian, time: dt)) / dt
    let varH = psi.expectation(hSquared) - pow(psi.expectation(hamiltonian), 2)
    print("    \(fmt(theta))   \(fmt(speed))            \(fmt(omega / 2 * sin(theta)))           \(fmt(max(0, varH).squareRoot()))")
}

let equatorial = ket(Double.pi / 2, 0)
let orthogonalTime = Double.pi / omega
let atAntipode = evolve(equatorial, hamiltonian, time: orthogonalTime)
print("    equator state at T = π/ω: overlap with start \(String(format: "%.2e", overlap(equatorial, atAntipode))), bound π/(2ΔH) = \(fmt(Double.pi / (2 * (omega / 2))))")
let offEquator = ket(Double.pi / 3, 0)
print("    θ = π/3 at T = π/ω: overlap with start \(fmt(overlap(offEquator, evolve(offEquator, hamiltonian, time: orthogonalTime))))")

// Unitary evolution keeps the distance between two states.
let pole = Ket.zero
for t in [0.0, 0.7, 1.9] {
    print("    t = \(t): D(|0⟩, equator state) = \(fmt(distance(evolve(pole, hamiltonian, time: t), evolve(equatorial, hamiltonian, time: t))))  (π/4 = \(fmt(Double.pi / 4)))")
}

// Adding a multiple of the identity to H changes only the overall phase.
let shifted = hamiltonian + I2 * 3.0
let tilted = ket(Double.pi / 3, 0.4)
print("    H + 3I vs H: overlap of evolved states \(fmt(overlap(evolve(tilted, hamiltonian, time: 1.3), evolve(tilted, shifted, time: 1.3))))")

// ------------------------------------------------------------
// §5 — Returning to a state with a phase to compare
// ------------------------------------------------------------

/// −arg of the product ⟨ψ₀|ψ₁⟩⟨ψ₁|ψ₂⟩…⟨ψₙ₋₁|ψ₀⟩ around a latitude circle.
func geometricPhase(theta: Double, increasing: Bool, steps: Int = 2000) -> Double {
    let sign = increasing ? 1.0 : -1.0
    var total = 0.0
    var current = ket(theta, 0)
    for k in 1...steps {
        let next = ket(theta, sign * 2 * Double.pi * Double(k) / Double(steps))
        total += (current† * next).argument
        current = next
    }
    return -total
}

print("\n§5  θ        γ computed   −Ω/2 = −π(1 − cos θ)")
for theta in [Double.pi / 6, Double.pi / 3, Double.pi / 2] {
    print("    \(fmt(theta))   \(fmt(geometricPhase(theta: theta, increasing: true)))    \(fmt(-Double.pi * (1 - cos(theta))))")
}
print("    θ = π/3, direction reversed: γ = \(fmt(geometricPhase(theta: Double.pi / 3, increasing: false)))")

// ------------------------------------------------------------
// §6 — When the state belongs to a larger system
// ------------------------------------------------------------

/// (|0⟩|A₀⟩ + e^{iφ}|1⟩|A₁⟩)/√2 with |A₀⟩ = |0⟩ and |A₁⟩ = cos χ|0⟩ + sin χ|1⟩, then a
/// recombiner on the path qubit. Returns the plus-port probability.
func plusPort(phi: Double, chi: Double) -> Double {
    let e = Complex(argument: phi)
    var joint = Ket([.one, .zero, e * cos(chi), e * sin(chi)])
    joint.apply(H ⊗ I2)
    return joint.marginalProbabilities(over: [0])["0"] ?? 0
}

print("\n§6  χ        |⟨A₀|A₁⟩|   φ        P(+) computed   (1 + cos χ cos φ)/2")
for chi in [0.0, Double.pi / 3, Double.pi / 2] {
    for phi in [0.0, Double.pi / 2, Double.pi] {
        let expected = (1 + cos(chi) * cos(phi)) / 2
        print("    \(fmt(chi))   \(fmt(abs(cos(chi))))    \(fmt(phi))   \(fmt(plusPort(phi: phi, chi: chi)))        \(fmt(expected))")
    }
}

print("\n    cos α|00⟩ + sin α|11⟩, first qubit alone:")
print("    α        |r| = cos 2α   Bloch z        purity (1 + cos²2α)/2   purity        entropy (bits)")
for alpha in [0.0, Double.pi / 8, Double.pi / 4] {
    let joint = Ket([Complex(cos(alpha)), .zero, .zero, Complex(sin(alpha))])
    let reduced = DensityMatrix(joint).partialTrace(keeping: [0])
    let z = reduced.blochVector?.z ?? .nan
    print("    \(fmt(alpha))   \(fmt(cos(2 * alpha)))       \(fmt(z))     \(fmt((1 + pow(cos(2 * alpha), 2)) / 2))                \(fmt(reduced.purity))      \(fmt(reduced.vonNeumannEntropy))")
}

// ------------------------------------------------------------
// §7 — From a probability to a record
// ------------------------------------------------------------

let rhoPlus = DensityMatrix(Ket.plus)
let projectorPlus = Ket.plus * (Ket.plus†)
let projectorMinus = Ket.minus * (Ket.minus†)
let projectorZero = Ket.zero * (Ket.zero†)
let projectorOne = Ket.one * (Ket.one†)
print("\n§7  ρ = |+⟩⟨+|")
print("    plus–minus test:  p(+) = \(fmt(rhoPlus.expectation(projectorPlus))), p(−) = \(fmt(rhoPlus.expectation(projectorMinus)))")
print("    which-path test:  p(0) = \(fmt(rhoPlus.expectation(projectorZero))), p(1) = \(fmt(rhoPlus.expectation(projectorOne)))")

// An unsharp pair E± = (I ± ηZ)/2 is a valid set of effects: E₊ + E₋ = I.
let eta = 0.6
let effectUp = (I2 + Z * eta) * 0.5
let effectDown = (I2 - Z * eta) * 0.5
let effectSum = effectUp + effectDown
var sumResidual = 0.0
for i in 0..<2 { for j in 0..<2 { sumResidual = max(sumResidual, (effectSum[i, j] - I2[i, j]).magnitude) } }
let rhoZero = DensityMatrix(Ket.zero)
print("    unsharp effects (η = \(eta)): max|E₊ + E₋ − I| = \(String(format: "%.2e", sumResidual))")
print("    on |0⟩: p(+) = \(fmt(rhoZero.expectation(effectUp))), p(−) = \(fmt(rhoZero.expectation(effectDown))); on |+⟩: p(+) = \(fmt(rhoPlus.expectation(effectUp)))")

// ------------------------------------------------------------
// Live view: fringe contrast and three Bloch vectors
// ------------------------------------------------------------

let phases = stride(from: 0.0, through: 2 * Double.pi, by: Double.pi / 40).map { $0 }
func fringe(_ visibility: Double) -> [CGPoint] {
    phases.map { CGPoint(x: $0, y: (1 + visibility * cos($0)) / 2) }
}

let reducedAtEighth = DensityMatrix(Ket([Complex(cos(Double.pi / 8)), .zero, .zero, Complex(sin(Double.pi / 8))]))
    .partialTrace(keeping: [0])

// Playground top-level code runs on the main thread, but is not marked main-actor isolated.
MainActor.assumeIsolated {
    let chart = CHSHChartView(
        title: "Plus-port probability P(+) against φ, by marker overlap",
        xRange: 0...(2 * Double.pi),
        yRange: 0...1,
        series: [
            CHSHChartView.Series(label: "|⟨A₀|A₁⟩| = 1", color: .blue, points: fringe(1), isLine: true),
            CHSHChartView.Series(label: "|⟨A₀|A₁⟩| = 0.5", color: .orange, points: fringe(0.5), isLine: true),
            CHSHChartView.Series(label: "|⟨A₀|A₁⟩| = 0", color: .red, points: fringe(0), isLine: true)
        ]
    )
    let spheres = HStack {
        BlochSphereView(label: "equator, φ = π/2", bloch: BlochVector(ket(Double.pi / 2, Double.pi / 2)))
        BlochSphereView(label: "latitude θ = π/3", bloch: BlochVector(ket(Double.pi / 3, 0)))
        if let reduced = reducedAtEighth.blochVector {
            BlochSphereView(label: "reduced qubit, α = π/8",
                            bloch: BlochVector(x: reduced.x, y: reduced.y, z: reduced.z))
        }
    }
    PlaygroundPage.current.setLiveView(VStack { chart; spheres }.padding())
}

//: [Next](@next)
