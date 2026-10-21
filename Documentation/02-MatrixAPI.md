# Matrix API

`Matrix` is declared in `SwiftQiskit/Sources/SwiftQiskit/Math/Matrix.swift` as `public typealias Matrix = GenericMatrix<Complex>`. The underlying type is `public struct GenericMatrix<Element: MatrixScalar>: Equatable, Hashable, CustomStringConvertible`, a row-major matrix. `GenericMatrix<Double>` gives real matrices. Extensions in `Dirac.swift` and `DensityMatrix.swift` add more.

## Element requirements (`MatrixScalar.swift`)
- `MatrixScalar`: requires `AdditiveArithmetic`, `Hashable`, `CustomStringConvertible`, `static var one`, `*`, `conjugate` and `magnitude: Double`.
- `Complex` and `Double` conform (for `Double`, `conjugate` returns the value itself). `Float` and `Int` do not; integer literals such as `GenericMatrix([[5, 2]])` are inferred as `Double`.

## Stored properties
- `public let rows: Int` and `public let cols: Int`: the dimensions.
- `var grid: [Element]`: internal; the row-major entries.

## Computed properties
- `adjoint: GenericMatrix`: the conjugate transpose A† (a plain transpose for real entries).
- `trace: Element`: the sum of the diagonal entries; traps if the matrix isn't square.
- `description: String`: from `CustomStringConvertible`; one `[a, b, …]` line per row.
- `permutationImage: [Int]?`: internal; the column→row mapping if the matrix is exactly a permutation matrix, otherwise `nil`. It drives the fast path in `StateVector.apply(_:)`.

## Initializers
- `init(rows:cols:repeating:)`: fills every entry with `repeating` (default `.zero`); dimensions must be positive.
- `init(_ data: [[Element]])`: builds from nested rows; traps if empty or if the rows differ in length.
- `init(rows:cols:elements:)`: internal; wraps row-major entries that are already laid out, without copying.

## Static factories
- `identity(size:)`: the `size`×`size` identity matrix.
- `permutation(size:image:)`: the permutation matrix sending basis column `i` to row `image(i)`; traps unless `image` is a bijection on `0..<size`.

## Methods
- `multiply(by vector: [Element]) -> [Element]`: matrix × vector.
- `tensor(_ other:) -> GenericMatrix`: the Kronecker product, with `self` as the high-order block; any dimensions are allowed.
- `isUnitary(tolerance: Double = 1e-10) -> Bool`: checks U†U ≈ I entrywise; `false` for a non-square matrix. Use this rather than `==`, which compares entries exactly.
- `expm(terms: Int = 20) -> Matrix`: `Matrix` only; the matrix exponential eᴬ via scaling and squaring. There is no implicit −i, so for e^(−iθH) scale `H` by `Complex(0, -theta)` first. Traps if the matrix isn't square.

## Operators and subscript
- `* (GenericMatrix, GenericMatrix)`: matrix product; inner dimensions must match (zero entries on the left are skipped).
- `+` and `-`: entrywise sum and difference; dimensions must match.
- `* (GenericMatrix, Element)` and `* (Element, GenericMatrix)`: scalar multiple.
- `* (Matrix, Double)` and `* (Double, Matrix)`: `Matrix` only; a real scalar multiple.
- `⊗ (GenericMatrix, GenericMatrix)`: the Kronecker product, the same as `tensor(_:)`. `⊗` is declared as `infix operator ⊗ : MultiplicationPrecedence`.
- Postfix `†` (global function in `Dirac.swift`): `Matrix` only; the same as `adjoint`.
- `subscript(row: Int, col: Int) -> Element`: get and set, with a bounds check.

## Interop with Dirac and density-matrix types
- `* (Bra, Matrix) -> Bra`: row vector × matrix, so `ψ† * U * ψ` works.
- `* (StateVector, Bra) -> Matrix`: outer product |ψ⟩⟨φ|.
- `⊗ (StateVector, Bra) -> Matrix`: |a⟩⟨b|; `⊗ (Bra, StateVector) -> Matrix`: |b⟩⟨a|.
- `StateVector.apply(_:)` and `StateVector.expectation(_:)` take a `Matrix`.
- `DensityMatrix.apply(_:)` (ρ → UρU†) and `DensityMatrix.expectation(_:)` take a `Matrix`.

## Design note: `GenericMatrix` versus a Complex-only `Matrix`
The early playgrounds use `GenericMatrix<Double>` for real matrices. The alternative is a single `Matrix` type with initializers that convert `Float`, `Double` and `Int` entries to `Complex`.

- **`GenericMatrix` (current)**
  - Pros: real matrices keep a real type and are cheaper to compute with; they can't be passed to the quantum APIs by mistake; every operation is written once against `MatrixScalar`.
  - Cons: there are two names to learn; there is no conversion from `GenericMatrix<Double>` to `Matrix`, so real matrices can't be applied to states and can't be mixed with `Matrix` in `*` or `⊗`; `†` and `expm` work only on `Matrix`.
- **Converting initializers on `Matrix`**
  - Pros: one type that works with every gate, state and operator; closest to the textbook notation.
  - Cons: overloads for several numeric types make literals such as `Matrix([[1, 2]])` ambiguous; real matrices always pay the cost of complex arithmetic; the conversion to `Complex` is silent.
  - To avoid the ambiguity, use labelled initializers (for example `Matrix(real:)`), or make `Complex` accept integer and float literals directly (`ExpressibleByIntegerLiteral` and `ExpressibleByFloatLiteral`). If you take the literal route, check that `m * 2` still resolves to a single scalar operator.
