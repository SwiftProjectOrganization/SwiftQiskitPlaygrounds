# Dirac API

`Dirac.swift` (`SwiftQiskit/Sources/SwiftQiskit/Quantum/Dirac.swift`) declares `public typealias Ket = StateVector`, `public struct Bra: Equatable`, the postfix operator `†`, and extensions on `Bra`, `StateVector` and `Matrix` for inner/outer products, expectation values and tensor products. `Bra` gets `CustomStringConvertible` in the same file.

## Ket
- `Ket` is a typealias of `StateVector`; everything in `03-StateVectorAPI.md` applies.
- `init(_ label: String)`: basis ket from a binary label such as `"01"`. Qubit 0 is the most-significant (leftmost) bit. Traps if the label is empty or contains anything other than `0` and `1`.
- Static constants `zero`, `one`, `plus`, `minus`, `plusI` (|i⟩) and `minusI` (|−i⟩), each normalized at construction.

## Bra

### Stored property
- `public private(set) var amplitudes: [Complex]`: the row-vector entries, stored already conjugated, so ⟨φ|ψ⟩ is a plain dot product.

### Initializers
- `init(_ ket: StateVector)`: the conjugate transpose of a ket.
- `init(_ label: String)`: basis bra, e.g. `Bra("01")` is ⟨01|.
- `fileprivate init(conjugatedAmplitudes:)`: internal; takes raw entries with no normalization. Used for the results of ⟨ψ|U and `⊗`.

### Computed properties
- `ket: StateVector`: the corresponding ket. It goes through `StateVector.init(_:)`, so it renormalizes.
- `dimension: Int`: the number of entries (2ⁿ).
- `description: String`: one `⟨k|: amp` line per entry.

## Dagger `†`
- `† (StateVector) -> Bra`: ⟨ψ| = (|ψ⟩)†.
- `† (Bra) -> StateVector`: |ψ⟩ = (⟨ψ|)†.
- `† (Matrix) -> Matrix`: the same as `adjoint`.
- `†` is U+2020 (⌥T on a US keyboard). ASCII equivalents: `Bra(ket)`, `bra.ket`, `matrix.adjoint`.

## Products
- `* (Bra, StateVector) -> Complex`: the inner product ⟨φ|ψ⟩. Traps if the dimensions differ.
- `* (Bra, Matrix) -> Bra`: ⟨ψ|U. The result is not normalized. Traps if `bra.dimension != matrix.rows`.
- `* (StateVector, Bra) -> Matrix`: the outer product |ψ⟩⟨φ|. The dimensions don't have to match.
- `ψ† * A * ψ` evaluates as `(ψ† * A) * ψ`, a `Bra` and then a `Complex`.
- `StateVector.expectation(_ observable: Matrix) -> Double`: the real part of ⟨ψ|A|ψ⟩. For a non-Hermitian `A` the imaginary part is silently dropped.

## Tensor products
- `Bra.tensor(_:)` and `⊗ (Bra, Bra) -> Bra`: `self` takes the high-order bits. `(a ⊗ b)† == a† ⊗ b†` holds exactly.
- `⊗ (StateVector, Bra) -> Matrix`: |a⟩⟨b|, the same as the outer product.
- `⊗ (Bra, StateVector) -> Matrix`: |b⟩⟨a|; note the swapped order.
- `⊗ (StateVector, StateVector) -> StateVector` is in `StateVector.swift` (see `03-StateVectorAPI.md`).

## Interop with other types
- `⟨φ|ψ⟩` and `ψ† * A * ψ` return `Complex` (see `01-ComplexAPI.md`).
- `†` on `Matrix`, and `Bra * Matrix`, use `Matrix` (see `02-MatrixAPI.md`). Gate matrices such as `HadamardGate.matrix` and `PauliXGate.matrix` work directly in `ψ† * G * ψ`.
- `Bra` is built from and converts back to `StateVector` (see `03-StateVectorAPI.md`).

## Gotchas
- `description` labels are not zero-padded: they use `String(offset, radix: 2)`, so a 2-qubit state prints `|0⟩`, `|1⟩`, `|10⟩`, `|11⟩`. `StateVector.description` does the same.
- `==` is exact. `(ψ†)† == ψ` is exactly true only because `normalize()` skips rescaling when the length is already within 1e-12 of 1. Once multiplication is involved, compare with a tolerance.
- A `Bra` produced by `* Matrix` or `⊗` is not normalized; converting it back with `.ket` or `†` renormalizes it.

## Not provided
- Bra arithmetic: no `Bra + Bra`, no scalar × `Bra`, no `Bra * Bra`.
- `Matrix * StateVector`; use the mutating `StateVector.apply(_:)`, or `ψ† * U` for the bra side.
- Zero-padded basis labels in `description`.
