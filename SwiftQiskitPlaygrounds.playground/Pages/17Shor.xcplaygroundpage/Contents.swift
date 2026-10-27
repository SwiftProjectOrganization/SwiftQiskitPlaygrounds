//: [Previous](@previous)
/*:
 # Shor's Algorithm, Compiled

 Factoring N reduces to finding the order r of a base a: the smallest r > 0 with
 aʳ ≡ 1 (mod N). This page runs the compiled N = 15 instance, the smallest number Shor can
 factor.

 - Classical reduction: if r is even and a^(r/2) ≢ −1, then `gcd(a^(r/2) ± 1, 15)` are factors.
 - Modular multiplication `w → a·w mod 15` is a 16 × 16 permutation matrix, applied with `apply(_:)`.
 - Phase estimation (Chapter 16) on that operator, with 3 counting qubits, gives
   y/8 = s/r exactly, so no continued fractions are needed.
 - Register layout: counting qubits 0–2, work qubits 3–6, index `count·16 + work`.
 - Counting qubit 0 controls `U^4`, which is the identity because every order mod 15 divides 4.
 - a = 14 ≡ −1 (mod 15) is the one coprime base that fails.
 - Order-2 bases compile down to a single `h`, two or four `cx`, and a closing `h`.

 Limit: there is no partial measurement, so the counting register's distribution is the
 marginal of the full probability vector, and shots are sampled from it directly.

 Follows Chapter 17 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

func modPow(_ base: Int, _ exponent: Int, _ modulus: Int) -> Int {
    var result = 1, square = base % modulus, e = exponent
    while e > 0 {
        if e & 1 == 1 { result = result * square % modulus }
        square = square * square % modulus
        e >>= 1
    }
    return result
}

func bits(_ value: Int, width: Int) -> String {
    let s = String(value, radix: 2)
    return String(repeating: "0", count: max(0, width - s.count)) + s
}

func fmt(_ value: Complex) -> String {
    func rounded(_ x: Double) -> Double { abs(x) < 1e-9 ? 0 : (x * 10_000).rounded() / 10_000 }
    return Complex(rounded(value.real), rounded(value.imag)).description
}

func pretty(_ state: StateVector, qubits: Int) -> String {
    (0..<state.dimension)
        .filter { state[$0].magnitude > 1e-10 }
        .map { "|\(bits($0, width: qubits))⟩: \(fmt(state[$0]))" }
        .joined(separator: "   ")
}

// ------------------------------------------------------------
// §1 — From factoring to order finding
// ------------------------------------------------------------

print(" a   gcd(a,15)")
for a in 2...14 {
    let g = gcd(a, 15)
    let note = g > 1 ? "lucky guess — \(g) is already a factor" : "coprime — needs the order r"
    print(String(format: "%2d       %2d      ", a, g) + note)
}

// ------------------------------------------------------------
// §2 — The classical answer key
// ------------------------------------------------------------

let powers = (0..<8).map { modPow(7, $0, 15) }
print("\n7^k mod 15, k = 0…7:", powers.map(String.init).joined(separator: " "))
let half7 = modPow(7, 2, 15)
print("7^2 ≡ \(half7): gcd(\(half7 - 1),15)=\(gcd(half7 - 1, 15)), gcd(\(half7 + 1),15)=\(gcd(half7 + 1, 15))")
// period r = 4, and 15 = 3 × 5 already

// ------------------------------------------------------------
// §3 — Modular multiplication as a permutation
// ------------------------------------------------------------

func modMultiplyGate(_ a: Int) -> Matrix {
    var m = Matrix(rows: 16, cols: 16)
    for w in 0..<15 { m[(a * w) % 15, w] = .one }
    m[15, 15] = .one    // |15⟩ is unused: a fixed point
    return m
}

let u7 = modMultiplyGate(7)
print("\nU₇ exactly unitary:", u7† * u7 == Matrix.identity(size: 16))
let orbit = QuantumCircuit(qubits: 4)
orbit.x(3)
print("start: ", pretty(orbit.run(), qubits: 4))
for step in 1...4 {
    orbit.apply(u7)
    print("U₇^\(step):  ", pretty(orbit.run(), qubits: 4))
}
// 1 → 7 → 4 → 13 → 1: the orbit closes after r = 4 steps

// ------------------------------------------------------------
// §4 — Two routes to the inverse QFT
// ------------------------------------------------------------

func cp(_ qc: QuantumCircuit, _ theta: Double, _ control: Int, _ target: Int) {
    qc.p(theta / 2, control); qc.cx(control, target); qc.p(-theta / 2, target)
    qc.cx(control, target); qc.p(theta / 2, target)
}
func swapQubits(_ qc: QuantumCircuit, _ a: Int, _ b: Int) { qc.cx(a, b); qc.cx(b, a); qc.cx(a, b) }
func appendInverseQFT(_ qc: QuantumCircuit, qubits n: Int) {
    for q in 0..<(n / 2) { swapQubits(qc, q, n - 1 - q) }
    for j in stride(from: n - 1, through: 0, by: -1) {
        for k in stride(from: n - 1, through: j + 1, by: -1) {
            cp(qc, -2 * Double.pi / pow(2.0, Double(k - j + 1)), k, j)
        }
        qc.h(j)
    }
}
func inverseQFTMatrix(size: Int) -> Matrix {
    var m = Matrix(rows: size, cols: size)
    let scale = 1.0 / sqrt(Double(size))
    for y in 0..<size {
        for c in 0..<size {
            let theta = -2.0 * Double.pi * Double(y * c) / Double(size)
            m[y, c] = Complex(magnitude: scale, argument: theta)
        }
    }
    return m
}

let qftDagger = inverseQFTMatrix(size: 8)
var maxDeviation = 0.0
for c in 0..<8 {
    let gateQC = QuantumCircuit(qubits: 3)
    let matrixQC = QuantumCircuit(qubits: 3)
    for q in 0..<3 where (c >> (2 - q)) & 1 == 1 { gateQC.x(q); matrixQC.x(q) }
    appendInverseQFT(gateQC, qubits: 3)
    matrixQC.apply(qftDagger)
    let g = gateQC.run().amplitudes, m = matrixQC.run().amplitudes
    for y in 0..<8 { maxDeviation = max(maxDeviation, (g[y] - m[y]).magnitude) }
}
print("\ngate-level inverse QFT vs. entrywise matrix, max deviation:", maxDeviation)
// ~1e-15: the same unitary

// ------------------------------------------------------------
// §5 — The full circuit for a = 7, stage by stage
// ------------------------------------------------------------

func controlledModMultiply(controlQubit: Int, multiplier: Int) -> Matrix {
    var m = Matrix(rows: 128, cols: 128)
    for index in 0..<128 {
        let count = index >> 4, work = index & 15
        var newWork = work
        if (count >> (2 - controlQubit)) & 1 == 1 && work < 15 { newWork = (multiplier * work) % 15 }
        m[(count << 4) | newWork, index] = .one
    }
    return m
}

print("\ncounting qubit k → controlled power of 7:")
for k in 0..<3 {
    let power = 1 << (2 - k)
    print("  qubit \(k) (bit weight \(power)):  U₇^\(power) = ×\(modPow(7, power, 15)) mod 15")
}

let shor7 = QuantumCircuit(qubits: 7)
for q in 0..<3 { shor7.h(q) }
shor7.x(6)
print("\nstage 1:", pretty(shor7.run(), qubits: 7))
for k in 0..<3 {
    shor7.apply(controlledModMultiply(controlQubit: k, multiplier: modPow(7, 1 << (2 - k), 15)))
}
print("stage 2:", pretty(shor7.run(), qubits: 7))
shor7.apply(qftDagger ⊗ Matrix.identity(size: 16))
let final7 = shor7.run()

print("\nstage 3, grouped by y:")
for y in 0..<8 {
    let terms = (0..<16)
        .filter { final7[(y << 4) | $0].magnitude > 1e-10 }
        .map { "work \($0): \(fmt(final7[(y << 4) | $0]))" }
    if !terms.isEmpty { print("  y = \(y):  \(terms.joined(separator: "   "))") }
}

// Marginal over the never-read work register.
var marginal7 = [Double](repeating: 0, count: 8)
for (index, p) in final7.probabilities.enumerated() { marginal7[index >> 4] += p }
print("\ny    P(y)")
for y in 0..<8 { print("\(y)    \(String(format: "%.4f", marginal7[y]))") }
// 0.25 at y = 0, 2, 4, 6; zero at odd y

// ------------------------------------------------------------
// §6 — Sampling the counting register
// ------------------------------------------------------------
// measure(shots:) replays the circuit per shot, which is slow at dimension 128, so
// sample one run's marginal directly: statistically identical for a pure state.

func sample(_ probabilities: [Double], shots: Int) -> [Int: Int] {
    var counts: [Int: Int] = [:]
    for _ in 0..<shots {
        var u = Double.random(in: 0..<1)
        var outcome = probabilities.count - 1
        for (index, p) in probabilities.enumerated() {
            u -= p
            if u < 0 { outcome = index; break }
        }
        counts[outcome, default: 0] += 1
    }
    return counts
}

let histogram7 = sample(marginal7, shots: 1000)
print("\n1000 shots of the counting register:")
for y in 0..<8 {
    if let count = histogram7[y] { print("  \(bits(y, width: 3)): \(count)") }
}
// four bins near 250 — a re-run jitters by about ±40

// ------------------------------------------------------------
// §7 — Classical post-processing
// ------------------------------------------------------------

print("\ny   phase   lowest terms   candidate r   7^r mod 15   verdict")
for y in [0, 2, 4, 6] {
    let g = gcd(y, 8), candidate = 8 / g, check = modPow(7, candidate, 15)
    print("\(y)   \(y)/8     \(y / g)/\(candidate)            \(candidate)             \(check)            \(check == 1 ? "✓ order found" : "✗ retry")")
}
let h7 = modPow(7, 2, 15)
print("\nr = 4:  7^(r/2) ≡ \(h7),  gcd(\(h7 - 1),15)=\(gcd(h7 - 1, 15)),  gcd(\(h7 + 1),15)=\(gcd(h7 + 1, 15))")
// y = 2 and 6 find r = 4; y = 0 says nothing; y = 4 gives r = 2, which fails the check

// ------------------------------------------------------------
// §8 — A base sweep, including the a = 14 failure
// ------------------------------------------------------------

func shorCircuit(a: Int) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 7)
    for q in 0..<3 { qc.h(q) }
    qc.x(6)
    for k in 0..<3 {
        qc.apply(controlledModMultiply(controlQubit: k, multiplier: modPow(a, 1 << (2 - k), 15)))
    }
    qc.apply(qftDagger ⊗ Matrix.identity(size: 16))
    return qc
}

func shorOrder(a: Int) -> Int? {
    var counting = [Double](repeating: 0, count: 8)
    for (index, p) in shorCircuit(a: a).run().probabilities.enumerated() { counting[index >> 4] += p }
    var best: Int?
    for y in 1..<8 where counting[y] > 1e-9 {
        let candidate = 8 / gcd(y, 8)
        if modPow(a, candidate, 15) == 1 { best = best.map { min($0, candidate) } ?? candidate }
    }
    return best
}

print("\n a    r    a^(r/2)   result")
for a in [2, 4, 7, 8, 11, 13, 14] {
    guard let order = shorOrder(a: a) else { print(String(format: "%2d    ?", a)); continue }
    let h = modPow(a, order / 2, 15)
    if order % 2 == 0, (h + 1) % 15 != 0 {
        print(String(format: "%2d    %d    %2d        15 = %d × %d", a, order, h, gcd(h - 1, 15), gcd(h + 1, 15)))
    } else {
        print(String(format: "%2d    %d    %2d        ✗ a^(r/2) ≡ −1 — trivial factors, pick another a", a, order, h))
    }
}
// six of seven coprime bases factor 15; only a = 14 fails

// ------------------------------------------------------------
// §9 — Compiling further: order 2 needs one counting qubit
// ------------------------------------------------------------
// q0 counts; q1–q4 are the work register, starting at |0001⟩. The single controlled
// multiplication acts on the classical value 1, so it is just a mask of cx gates:
// 1 ⊕ a in four bits (11 → 1010, 14 → 1111).

func compiledOrder2(maskTargets: [Int]) -> QuantumCircuit {
    let qc = QuantumCircuit(qubits: 5)
    qc.x(4)
    qc.h(0)
    for target in maskTargets { qc.cx(0, target) }
    qc.h(0)
    return qc
}

let compiled11 = compiledOrder2(maskTargets: [1, 3])
let compiled14 = compiledOrder2(maskTargets: [1, 2, 3, 4])
print("\na = 11 compiled:", pretty(compiled11.run(), qubits: 5))
print("a = 14 compiled:", pretty(compiled14.run(), qubits: 5))
// q0 = 1 reads r = 2 in both; 11 factors 15 (gcd(10,15) = 5, gcd(12,15) = 3), 14 does not

let shots11 = compiled11.measure(shots: 1000)
print("a = 11, 1000 shots:", shots11.sortedCounts.map { "\($0.state): \($0.count)" })

// ------------------------------------------------------------
// §10 — Live view
// ------------------------------------------------------------
// The counting-register distribution for a = 7, and the compiled a = 11 shot histogram.
// Stateless views (no @State) — required for page code.

struct CountingBars: View {
    let title: String
    let values: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(values.indices, id: \.self) { y in
                    VStack(spacing: 2) {
                        Text(String(format: "%.2f", values[y]))
                            .font(.system(size: 9, design: .monospaced))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: 32, height: max(1, 100 * CGFloat(values[y])))
                        Text("y=\(y)")
                            .font(.system(size: 9, design: .monospaced))
                    }
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
        .padding(8)
    }
}

struct CountHistogram: View {
    let title: String
    let result: SimulationResult

    var body: some View {
        let sorted = result.sortedCounts
        let maxCount = max(sorted.map(\.count).max() ?? 1, 1)

        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) (\(result.shots) shots)")
                .font(.headline)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(sorted, id: \.state) { entry in
                    VStack(spacing: 2) {
                        Text("\(entry.count)")
                            .font(.system(size: 8, design: .monospaced))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: 36, height: 80 * CGFloat(entry.count) / CGFloat(maxCount))
                        Text(entry.state)
                            .font(.system(size: 8, design: .monospaced))
                    }
                }
            }
            .frame(height: 110, alignment: .bottom)
        }
        .padding(8)
    }
}

struct ShorView: View {
    let marginal: [Double]
    let compiled: SimulationResult

    var body: some View {
        VStack(spacing: 16) {
            CountingBars(title: "a = 7: P(y) over the counting register", values: marginal)
            CountHistogram(title: "a = 11 compiled, order 2", result: compiled)
        }
        .padding()
    }
}

PlaygroundPage.current.setLiveView(
    ShorView(marginal: marginal7, compiled: shots11)
        .frame(width: 520, height: 420)
)

//: [Next](@next)
