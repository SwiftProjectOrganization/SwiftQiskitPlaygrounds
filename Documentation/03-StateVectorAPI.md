# StateVector API

`StateVector` is declared in `SwiftQiskit/Sources/SwiftQiskit/Quantum/StateVector.swift` as `public struct StateVector: Equatable`. Extensions in `Dirac.swift` and `StateVector+Kernels.swift` add more.

## Stored property
- `public internal(set) var amplitudes: [Complex]`: the state's complex amplitudes, read-only from outside the package.

## Computed properties
- `dimension: Int`: the number of basis states (2ⁿ).
- `probabilities: [Double]`: the squared magnitude of each amplitude.
- `private var qubitCount: Int`: the number of qubits, derived from `dimension` (in the Marginals extension).
- `description: String`: from `CustomStringConvertible`; prints each amplitude as `|01⟩: amp`.

## Initializers
- `init(_ amplitudes: [Complex])`: takes raw amplitudes and normalizes them.
- `init(qubits: Int)`: creates the |0…0⟩ state.
- `init(_ label: String)`: creates a basis ket from a binary label such as `"01"` (`Dirac.swift`).

## Static constants (`Dirac.swift`)
- `zero` (|0⟩), `one` (|1⟩), `plus` (|+⟩), `minus` (|−⟩), `plusI` (|i⟩), `minusI` (|−i⟩).
- `static let parallelThreshold = 1 << 14`: internal, in the kernels extension.

## Methods
- `mutating normalize()`: rescales so the probabilities sum to 1; does nothing if already normalized.
- `mutating measure() -> Int`: samples one basis state and collapses the state to it (uses a private `collapse(to:)` helper).
- `mutating apply(_ matrix: Matrix)`: applies an operator; permutation matrices take a faster O(2ⁿ) path.
- `tensor(_ other:) -> StateVector`: the tensor product, with `self` as the high-order bits.
- `marginalProbabilities(over qubits: [Int]) -> [String: Double]`: the probability distribution over a chosen subset of qubits.
- `expectation(_ observable: Matrix) -> Double`: the real part of ⟨ψ|A|ψ⟩.
- `mutating applyLocal(_ tensor:targets:parallel:)`: internal; applies a gate to only the target qubits, splitting work across threads for large states.
- `static sampleIndex(from:)` and `static sampleIndices(from:count:)`: internal helpers for sampling measurement outcomes.

## Operators and subscript
- `⊗ (StateVector, StateVector) -> StateVector`: tensor product.
- `* (StateVector, Bra) -> Matrix`: outer product |ψ⟩⟨φ|.
- `⊗ (StateVector, Bra) -> Matrix`: mixed tensor product, same as the outer product.
- Postfix `†` (global function in `Dirac.swift`): turns a `StateVector` into a `Bra`; the matching `†` on `Bra` turns it back.
- `subscript(index: Int) -> Complex`: reads one amplitude, with a bounds check.
