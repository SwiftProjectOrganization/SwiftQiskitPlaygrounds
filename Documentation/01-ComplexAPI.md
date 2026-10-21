# Complex API

`Complex` is declared in `SwiftQiskit/Sources/SwiftQiskit/Math/Complex.swift` as `public struct Complex: Equatable, Hashable`. An extension in the same file adds `CustomStringConvertible`; `MatrixScalar.swift` adds `AdditiveArithmetic` and `MatrixScalar`.

## Stored properties
- `public var real: Double`: the real part.
- `public var imag: Double`: the imaginary part.

## Initializer
- `init(_ real: Double = 0.0, _ imag: Double = 0.0)`: both arguments are unlabelled and default to 0, so `Complex()` is 0 and `Complex(3)` is 3.

## Static constants
- `zero` (0), `one` (1), `i` (the imaginary unit).

## Computed properties
- `magnitude: Double`: |z|, the square root of `real² + imag²`.
- `magnitudeSquared: Double`: |z|²; avoids the square root (used for probabilities).
- `conjugate: Complex`: z̄, the same real part with the sign of `imag` flipped.
- `description: String`: from `CustomStringConvertible`, using plain `Double` printing with no rounding:
  - `imag == 0`: `"3.0"`
  - `real == 0`: `"2.0i"`
  - otherwise: `"1.0 + 2.0i"` or `"1.0 - 2.0i"`

## Operators
- `+`, `-`, `*`, `/` between two `Complex` values. `/` traps (precondition) if the divisor is zero.
- `* (Complex, Double)` and `* (Double, Complex)`: a real scalar multiple.
- `+=`, `-=` and prefix `+`: the defaults that come with `AdditiveArithmetic`.
- `==` and hashing compare `real` and `imag` exactly, so compare computed results with a tolerance on `magnitude` of the difference.

## Protocol conformances
- `Equatable`, `Hashable`, `CustomStringConvertible`, `AdditiveArithmetic`.
- `MatrixScalar`: lets `Complex` be a `GenericMatrix` element (see `02-MatrixAPI.md`).

## Interop with other types
- `Matrix` is `GenericMatrix<Complex>`, so every `Matrix` entry is a `Complex`.
- `StateVector` stores `amplitudes: [Complex]`, takes `[Complex]` in `init(_:)`, and returns a `Complex` from `subscript(index:)`.
- `* (Bra, StateVector) -> Complex`: the inner product ⟨φ|ψ⟩ (`Dirac.swift`).
- `Matrix.expm` has no implicit −i; for e^(−iθH) scale `H` by `Complex(0, -theta)`.

## Not provided
- Prefix `-` (use `.zero - z` or `z * -1.0`), `*=` and `/=`.
- Mixed `Complex + Double`, `Complex - Double` and `Complex / Double`.
- Phase/argument, polar initializer and `exp`; for e^(iθ) write `Complex(cos(θ), sin(θ))`.
- Integer and float literal conformance, so write `Complex(2)` rather than `2`.
