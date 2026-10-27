# Complex API

`Complex` is declared in `SwiftQiskit/Sources/SwiftQiskit/Math/Complex.swift` as `public struct Complex: Equatable, Hashable`. An extension in the same file adds `CustomStringConvertible`; `MatrixScalar.swift` adds `AdditiveArithmetic` and `MatrixScalar`. Polar-form members and `/ Double` need SwiftQiskit 0.9.0 or later; `ComplexVector.swift` (also 0.9.0) adds arithmetic on `[Complex]`.

## Stored properties
- `public var real: Double`: the real part.
- `public var imag: Double`: the imaginary part.

## Initializer
- `init(_ real: Double = 0.0, _ imag: Double = 0.0)`: both arguments are unlabelled and default to 0, so `Complex()` is 0 and `Complex(3)` is 3.

## Polar initializer
- `init(magnitude: Double = 1.0, argument: Double)`: r·e^(iθ), that is `(r·cos θ, r·sin θ)`. `Complex(argument: θ)` is the unit phase e^(iθ).

## Static constants
- `zero` (0), `one` (1), `i` (the imaginary unit).

## Computed properties
- `magnitude: Double`: |z|, the square root of `real² + imag²`.
- `magnitudeSquared: Double`: |z|²; avoids the square root (used for probabilities).
- `conjugate: Complex`: z̄, the same real part with the sign of `imag` flipped.
- `argument: Double`: arg(z) = `atan2(imag, real)`, in (−π, π]. It is 0 for z = 0.
- `description: String`: from `CustomStringConvertible`, using plain `Double` printing with no rounding:
  - `imag == 0`: `"3.0"`
  - `real == 0`: `"2.0i"`
  - otherwise: `"1.0 + 2.0i"` or `"1.0 - 2.0i"`

## Operators
- `+`, `-`, `*`, `/` between two `Complex` values. `/` traps (precondition) if the divisor is zero.
- `* (Complex, Double)` and `* (Double, Complex)`: a real scalar multiple.
- `/ (Complex, Double)`: division by a real scalar. Traps if the divisor is zero.
- Prefix `-`: negation.
- `+=`, `-=` and prefix `+`: the defaults that come with `AdditiveArithmetic`.
- `==` and hashing compare `real` and `imag` exactly, so compare computed results with a tolerance on `magnitude` of the difference.

## Functions
- `static exp(_ z: Complex) -> Complex`: e^z = e^(re)·(cos im + i·sin im). `Complex.exp(Complex(0, .pi))` is −1 up to a rounding error of about 1.2e-16 in the imaginary part.
- `static pow(_ z: Complex, _ n: Int) -> Complex`: zⁿ by repeated squaring, so small Gaussian integers stay exact (`pow(.i, 4) == .one`). A negative `n` gives 1/z^|n|; traps for z = 0 and n < 0.
- `static pow(_ z: Complex, _ x: Double) -> Complex`: zˣ on the principal branch, |z|ˣ·e^(i·x·arg z). Returns 0 for z = 0 and x > 0, and traps for z = 0 and x ≤ 0.
- These are static members, so they do not shadow Foundation's `exp` and `pow` on `Double`.

## Arithmetic on `[Complex]`
Extension on `Array where Element == Complex` in `Math/ComplexVector.swift`. These are named methods, not operators, because `Array` already uses `+` for concatenation.
- `adding(_:)` and `subtracting(_:)`: element-wise; trap if the lengths differ.
- `scaled(by: Complex)` and `scaled(by: Double)`: every element times a scalar.
- `inner(_:) -> Complex`: ⟨self|other⟩ = Σ conj(selfᵢ)·otherᵢ. It conjugates the receiver; traps if the lengths differ.
- `normSquared: Double` and `norm: Double`: Σ|aᵢ|² and its square root.
- `normalized() -> [Complex]`: the vector divided by its norm; traps for a zero vector.
- Unlike `StateVector`, none of these normalize, so a vector such as |0⟩ + |1⟩ can exist before it is normalized.

## Protocol conformances
- `Equatable`, `Hashable`, `CustomStringConvertible`, `AdditiveArithmetic`.
- `MatrixScalar`: lets `Complex` be a `GenericMatrix` element (see `02-MatrixAPI.md`).

## Interop with other types
- `Matrix` is `GenericMatrix<Complex>`, so every `Matrix` entry is a `Complex`.
- `StateVector` stores `amplitudes: [Complex]`, takes `[Complex]` in `init(_:)`, and returns a `Complex` from `subscript(index:)`.
- `* (Bra, StateVector) -> Complex`: the inner product ⟨φ|ψ⟩ (`Dirac.swift`). It agrees with `phi.amplitudes.inner(psi.amplitudes)` on the raw arrays.
- `Matrix.expm` has no implicit −i; for e^(−iθH) scale `H` by `Complex(0, -theta)`.

## Not provided
- `*=` and `/=`.
- Mixed `Complex + Double` and `Complex - Double`; write `Complex(d, 0)`.
- Operators on `[Complex]`; use the named methods above.
- Integer and float literal conformance, so write `Complex(2)` rather than `2`.
