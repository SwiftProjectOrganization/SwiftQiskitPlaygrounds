//: [Previous](@previous)
/*:
 # Applying gates directly to a state vector

 An n-qubit state is a vector ψ of 2ⁿ complex amplitudes. The textbook way to apply a
 gate U to qubit t is to build `I ⊗ … ⊗ U ⊗ … ⊗ I` (a 2ⁿ × 2ⁿ matrix) and multiply: O(4ⁿ)
 memory and time per gate. 20 qubits would need a 16 TB matrix.

 But U only ever mixes amplitudes whose indices differ in one bit b alone. The state splits into
 2ⁿ⁻¹ independent **pairs** `(i0, i1)` with `i1 = i0 | (1 << b)`, and each pair gets one tiny
 2×2 matrix–vector product. That is O(2ⁿ) time and O(1) extra memory — the same answer as the
 big matrix, minus every multiplication by zero.

 Controlled gates fall out for free: only update pairs whose index has every control bit set
 to 1. CNOT is controlled-X, CZ is controlled-Z, Toffoli is X with two controls.

 **Bit order.** This page uses SwiftQiskit Core's convention — qubit 0 is the *most*-significant
 bit (`|q0 q1 q2⟩ ↔ index q0·4 + q1·2 + q2`), so qubit `q` of an n-qubit register lives at bit
 position `b = n-1-q`. (Qiskit numbers the other way, with qubit 0 as the least-significant
 bit.) §5 checks this code against `QuantumCircuit.run()` gate for gate.

 Playground code is slow (instrumented), so this page sticks to small registers and checks
 correctness only — no timings.
 */

import Foundation
import SwiftQiskit

// ------------------------------------------------------------
// §1 — The code
// ------------------------------------------------------------

typealias Amplitude = Complex   // SwiftQiskit's own complex number

/// A single-qubit gate as a 2×2 unitary, row-major: [[u00, u01], [u10, u11]].
struct Gate1 {
    var u00, u01, u10, u11: Amplitude

    init(_ u00: Amplitude, _ u01: Amplitude, _ u10: Amplitude, _ u11: Amplitude) {
        (self.u00, self.u01, self.u10, self.u11) = (u00, u01, u10, u11)
    }

    private static let r = 1 / Double(2).squareRoot()

    static let h = Gate1(Amplitude(r), Amplitude(r), Amplitude(r), Amplitude(-r))
    static let x = Gate1(.zero, .one, .one, .zero)
    static let y = Gate1(.zero, Amplitude(0, -1), Amplitude(0, 1), .zero)
    static let z = Gate1(.one, .zero, .zero, Amplitude(-1))
    static let s = Gate1(.one, .zero, .zero, Amplitude(0, 1))
    static let t = Gate1(.one, .zero, .zero, Amplitude(r, r))

    /// Rz(θ) = diag(e^{-iθ/2}, e^{+iθ/2})
    static func rz(_ theta: Double) -> Gate1 {
        Gate1(Amplitude(cos(theta / 2), -sin(theta / 2)), .zero,
              .zero, Amplitude(cos(theta / 2), sin(theta / 2)))
    }

    /// Ry(θ) — real rotation, handy for variational circuits.
    static func ry(_ theta: Double) -> Gate1 {
        let c = Amplitude(cos(theta / 2)), s = Amplitude(sin(theta / 2))
        return Gate1(c, Amplitude(-sin(theta / 2)), s, c)
    }
}

/// Lets a raw pointer cross into `concurrentPerform`'s closure. Safe because every chunk
/// touches a disjoint set of amplitude indices (same idiom as Core's `SharedPointer`).
struct SharedPointer: @unchecked Sendable {
    let base: UnsafeMutablePointer<Amplitude>
}


struct StateVectorCPU {
    let qubitCount: Int
    private(set) var amplitudes: [Amplitude]

    /// Starts in |00…0⟩.
    init(qubits n: Int) {
        precondition(n > 0 && n <= 30, "2^30 amplitudes is already 16 GB")
        qubitCount = n
        amplitudes = Array(repeating: .zero, count: 1 << n)
        amplitudes[0] = .one
    }

    // Serial version (clearest; best for small n)

    /// Applies `gate` to qubit `target`, optionally conditioned on `controls`
    /// all being |1⟩.
    mutating func apply(_ gate: Gate1, to target: Int, controls: [Int] = []) {
        let controlMask = mask(for: controls, target: target)
        let step = 1 << bit(of: target)  // distance between partners i0 and i1
        let dim = amplitudes.count

        // Indices come in blocks of 2·step: the first half of each block has bit b = 0
        // (that's i0), the second half has bit b = 1.
        //   b = 0: blocks [0,1] [2,3] …        pairs (0,1) (2,3) …
        //   b = 2: blocks [0…7] [8…15] …       pairs (0,4) (1,5) (2,6) (3,7) …
        amplitudes.withUnsafeMutableBufferPointer { psi in
            var block = 0
            while block < dim {
                for k in 0..<step {
                    let i0 = block + k
                    // Controlled gate: skip unless every control bit is 1.
                    if i0 & controlMask != controlMask { continue }
                    let i1 = i0 + step
                    let a0 = psi[i0], a1 = psi[i1]   // read both BEFORE writing
                    psi[i0] = gate.u00 * a0 + gate.u01 * a1
                    psi[i1] = gate.u10 * a0 + gate.u11 * a1
                }
                block += 2 * step
            }
        }
    }

    // Parallel version (worthwhile for roughly n ≥ 16)

    /// Same result as `apply`, split across CPU cores.
    ///
    /// Number the 2ⁿ⁻¹ pairs p = 0, 1, 2, … and compute i0 directly by inserting a 0 bit at
    /// bit position b into p:  i0 = (high bits of p shifted up one) | (low b bits of p).
    /// e.g. b = 1, p = 0b101 → high = 0b10, low = 0b1 → i0 = 0b1001.
    /// Every pair is independent, so any chunk of p values can run on any core, lock-free.
    mutating func applyParallel(_ gate: Gate1, to target: Int, controls: [Int] = []) {
        let controlMask = mask(for: controls, target: target)
        let b = bit(of: target)
        let step = 1 << b
        let lowMask = step - 1
        let pairCount = amplitudes.count / 2
        let chunks = min(pairCount, ProcessInfo.processInfo.activeProcessorCount * 4)
        let chunkSize = (pairCount + chunks - 1) / chunks

        amplitudes.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            let shared = SharedPointer(base: base)
            DispatchQueue.concurrentPerform(iterations: chunks) { chunk in
                let psi = shared.base
                let start = chunk * chunkSize
                let end = min(start + chunkSize, pairCount)
                guard start < end else { return }
                for p in start..<end {
                    let i0 = ((p >> b) << (b + 1)) | (p & lowMask)
                    if i0 & controlMask != controlMask { continue }
                    let i1 = i0 | step
                    let a0 = psi[i0], a1 = psi[i1]
                    psi[i0] = gate.u00 * a0 + gate.u01 * a1
                    psi[i1] = gate.u10 * a0 + gate.u11 * a1
                }
            }
        }
    }

    // Conveniences

    mutating func cnot(control: Int, target: Int) {
        apply(.x, to: target, controls: [control])
    }

    /// |ψᵢ|² for every basis state — what measurement samples from.
    var probabilities: [Double] {
        amplitudes.map { $0.magnitudeSquared }
    }

    /// Bit position of `qubit` in an amplitude index. Core's qubit 0 is the most-significant
    /// bit, so qubit q sits at bit n-1-q.
    private func bit(of qubit: Int) -> Int {
        qubitCount - 1 - qubit
    }

    private func mask(for controls: [Int], target: Int) -> Int {
        precondition((0..<qubitCount).contains(target), "target out of range")
        var m = 0
        for c in controls {
            precondition((0..<qubitCount).contains(c) && c != target, "bad control \(c)")
            m |= 1 << bit(of: c)
        }
        return m
    }
}

// ------------------------------------------------------------
// §2 — A Bell state
// ------------------------------------------------------------

var bell = StateVectorCPU(qubits: 2)
bell.apply(.h, to: 0)
bell.cnot(control: 0, target: 1)
print(bell.probabilities)
// [0.5, 0.0, 0.0, 0.5] (up to rounding) — |00⟩ and |11⟩

// ------------------------------------------------------------
// §3 — The pairs a gate touches (n = 3)
// ------------------------------------------------------------
// Two ways to enumerate them: block/offset loops (serial `apply`) and bit insertion
// (`applyParallel`). They must list the same pairs. Here `t` is a bit position (for n = 3,
// bit 2 is qubit 0, bit 1 is qubit 1, bit 0 is qubit 2).

for t in 0..<3 {
    let step = 1 << t
    var byBlocks: [[Int]] = []
    var block = 0
    while block < 8 {
        for k in 0..<step { byBlocks.append([block + k, block + k + step]) }
        block += 2 * step
    }
    let byInsertion = (0..<4).map { p -> [Int] in
        let i0 = ((p >> t) << (t + 1)) | (p & (step - 1))
        return [i0, i0 | step]
    }
    print("t = \(t): \(byBlocks)  same pairs: \(byBlocks.sorted { $0[0] < $1[0] } == byInsertion.sorted { $0[0] < $1[0] })")
}
// t = 0: [[0, 1], [2, 3], [4, 5], [6, 7]]  same pairs: true
// t = 1: [[0, 2], [1, 3], [4, 6], [5, 7]]  same pairs: true
// t = 2: [[0, 4], [1, 5], [2, 6], [3, 7]]  same pairs: true

// ------------------------------------------------------------
// §4 — Bit order: same convention as Core
// ------------------------------------------------------------
// Qubit 0 is the most-significant bit, so H on qubit 0 of 3 qubits mixes indices 0 and 4.

var cpu3 = StateVectorCPU(qubits: 3)
cpu3.apply(.h, to: 0)
print(cpu3.probabilities)
// [0.5, 0, 0, 0, 0.5, 0, 0, 0] (up to rounding)

let coreCircuit3 = QuantumCircuit(qubits: 3)
coreCircuit3.h(0)
print(coreCircuit3.run().probabilities)
// Same output. (Qiskit's qubit 0 = LSB would give indices 0 and 1 instead.)

// ------------------------------------------------------------
// §5 — Cross-check against Core's run()
// ------------------------------------------------------------
// The same 5-qubit circuit on both, with identical qubit labels, so the amplitude at index i
// agrees directly. It includes a Toffoli (two controls) and a CZ (controlled-Z).

//let n = 5
//var cpu = StateVectorCPU(qubits: n)
//let core = QuantumCircuit(qubits: n)
//
//for q in 0..<n {
//    cpu.apply(.h, to: q)
//    core.h(q)
//}
//cpu.apply(.t, to: 1);          core.t(1)
//cpu.apply(.s, to: 3);          core.s(3)
//cpu.apply(.y, to: 0);          core.y(0)
//cpu.apply(.rz(0.7), to: 2);    core.rz(0.7, 2)
//cpu.apply(.ry(1.3), to: 4);    core.ry(1.3, 4)
//cpu.cnot(control: 0, target: 3); core.cx(0, 3)
//cpu.apply(.x, to: 4, controls: [1, 2]);  core.ccx(1, 2, 4)   // Toffoli
//cpu.apply(.z, to: 2, controls: [4]);     core.cz(4, 2)               // CZ
//cpu.apply(.ry(-0.4), to: 1);   core.ry(-0.4, 1)
//cpu.cnot(control: 3, target: 0); core.cx(3, 0)
//
//let coreState = core.run()
//var maxDiff = 0.0
//for i in 0..<(1 << n) {
//    let a = cpu.amplitudes[i]
//    let b = coreState.amplitudes[i]
//    maxDiff = max(maxDiff, (a - b).magnitude)
//}
//print("max |Δ| vs Core:", maxDiff)
// ~1e-16 — direct pair updates and Core's embedded circuit agree amplitude for amplitude

// ------------------------------------------------------------
// §6 — Serial vs. parallel
// ------------------------------------------------------------
// Same gate sequence at n = 10 through `apply` and `applyParallel`. The arithmetic per
// pair is identical, so the results should match exactly.

//var serial = StateVectorCPU(qubits: 10)
//var parallel = StateVectorCPU(qubits: 10)
//for q in 0..<10 {
//    serial.apply(.h, to: q);               parallel.applyParallel(.h, to: q)
//    serial.apply(.rz(0.3 * Double(q + 1)), to: q)
//    parallel.applyParallel(.rz(0.3 * Double(q + 1)), to: q)
//}
//for q in 0..<9 {
//    serial.apply(.x, to: q + 1, controls: [q])
//    parallel.applyParallel(.x, to: q + 1, controls: [q])
//}
//let parallelDiff = zip(serial.amplitudes, parallel.amplitudes)
//    .map { ($0 - $1).magnitude }.max() ?? 0
//print("max |Δ| serial vs parallel:", parallelDiff)
// 0.0
// Core switches to the parallel path at 2¹⁴ amplitudes (`StateVector.parallelThreshold`);
// below that, thread start-up costs more than it saves.

// ------------------------------------------------------------
// §7 — Why it matters: memory per gate
// ------------------------------------------------------------
//
//for qubits in [4, 8, 12, 16, 20, 30] {
//    let dense = pow(4.0, Double(qubits)) * 16     // 2ⁿ×2ⁿ complex matrix, 16 bytes each
//    let vector = pow(2.0, Double(qubits)) * 16    // 2ⁿ amplitudes
//    print("n = \(qubits): dense matrix \(dense) bytes, state vector \(vector) bytes")
//}
// n = 20: ~1.76e13 bytes (16 TB) vs ~1.68e7 bytes (16 MB)
//
// Core's `StateVector.applyLocal` (Quantum/StateVector+Kernels.swift) generalizes this page
// to k-qubit gate tensors (same qubit-0-is-MSB convention), with dedicated diagonal and 1-qubit fast paths.

//: [Next](@next)
