# Noise, Tomography and Variational API

Pages `21Noise`, `22Tomography`, `23VQE` and `24Trotter` build their tools by hand from `Matrix`, `StateVector` and the gates, so each step stays visible. SwiftQiskit has library versions of the same tools in `SwiftQiskit/Sources/SwiftQiskit/Quantum/`. This document describes them and maps each page helper to its library equivalent, so the page results can be checked against the library.

| Page helper | Library equivalent |
|-------------|--------------------|
| `21Noise`: `rho(ψ)`, `purity`, `blochOf`, `partialTraceLast`, `entropy(of:)` | `DensityMatrix(ψ)`, `.purity`, `.blochVector`, `.partialTrace(keeping: [0])`, `.vonNeumannEntropy` |
| `21Noise`: `bitFlipKraus`, `phaseFlipKraus`, `depolarizingKraus`, `ampDampingKraus`, `applyChannel` | `KrausChannel.bitFlip`, `.phaseFlip`, `.depolarizing`, `.amplitudeDamping`, `apply(to:)` (same operators and conventions) |
| `22Tomography`: `basisRotation`, `estimate(_:psi:shots:)`, `clamped(_:_:_:)` | `QuantumCircuit.measure(shots:basis:)`, `StateTomography.estimateBlochVector`, `StateTomography.clampToPhysical` |
| `23VQE`: `H` as a sum of `Matrix` terms, `energy`, `parameterShiftGradient`, the descent loop (learning rate 1; the library default is 0.1) | `Hamiltonian` of `PauliString`s, `Hamiltonian.expectation`, `ParameterShift.gradient`, `GradientDescent.minimize` |
| `24Trotter`: `trotterUnitary`, the hand-built Trotter circuit | `Hamiltonian.trotterCircuit(time:steps:order:)`, `QuantumCircuit.evolve` |
| `24Trotter`: the exact `e^(−iHt)` | `Matrix.expm()` (`02-MatrixAPI.md`), which the page now uses directly |

## DensityMatrix
`public struct DensityMatrix: Equatable` (`DensityMatrix.swift`). Every public initializer checks that the matrix is square, 2ⁿ-sized, Hermitian and has trace 1 (tolerance 1e-6), and traps otherwise.
- `matrix: Matrix` and `qubits: Int`.
- `init(_ state: StateVector)`: the pure state |ψ⟩⟨ψ|.
- `init(mixture: [(probability: Double, state: StateVector)])`: Σ pᵢ|ψᵢ⟩⟨ψᵢ|. Probabilities must be non-negative and sum to 1 (within 1e-9).
- `init(matrix:)`: wraps and validates a raw matrix.
- `purity: Double`: Tr(ρ²); 1 for a pure state, 1/2ⁿ for the maximally mixed state.
- `probabilities: [Double]`: the diagonal.
- `expectation(_ observable: Matrix) -> Double`: the real part of Tr(ρA).
- `fidelity(to state: StateVector) -> Double`: ⟨ψ|ρ|ψ⟩.
- `apply(_ unitary: Matrix) -> DensityMatrix`: UρU†. Returns a new value; it is not mutating.
- `partialTrace(keeping qubits: [Int]) -> DensityMatrix`: traces out the other qubits; the kept qubits appear in the order given.
- `blochVector: (x: Double, y: Double, z: Double)?`: (Tr ρX, Tr ρY, Tr ρZ) for one qubit, otherwise `nil`. The length is below 1 for a mixed state.
- `eigenvalues: [Double]` (ascending) and `vonNeumannEntropy: Double` (in bits).

## KrausChannel and NoiseModel
`public struct KrausChannel` (`KrausChannel.swift`):
- `operators: [Matrix]` and `init(operators:)`: at least one operator, all square and the same size.
- `isTracePreserving(tolerance: Double = 1e-10) -> Bool`: checks Σ Kᵢ†Kᵢ ≈ I.
- `apply(to rho: DensityMatrix) -> DensityMatrix`: ρ' = Σ KᵢρKᵢ† on the whole register.
- `apply(to rho: DensityMatrix, qubit: Int) -> DensityMatrix`: a 2×2 channel on one qubit of a larger register.
- Single-qubit factories, each trapping outside [0, 1]:
  - `bitFlip(_ p:)` and `phaseFlip(_ p:)`: X or Z with probability p.
  - `depolarizing(_ p:)`: X, Y, Z with probability p/4 each.
  - `amplitudeDamping(_ gamma:)`: T1-style decay toward |0⟩.
  - `phaseDamping(_ lambda:)`: T2-style dephasing with no energy loss.

`public struct NoiseModel` (`NoiseModel.swift`):
- `init(singleQubitGate: KrausChannel? = nil, multiQubitGate: KrausChannel? = nil)`: both channels must be 2×2 and trace-preserving. The multi-qubit channel is applied to each touched qubit independently.
- `static func uniform(_ channel:) -> NoiseModel`: the same channel after every gate.

Running a circuit with noise (`05-QuantumCircuitAPI.md`):
- `QuantumCircuit.runDensityMatrix(noise: NoiseModel? = nil) -> DensityMatrix`: exact. Applies noise to every qubit a gate touched, right after that gate. With `nil` it equals `DensityMatrix(run())`.
- `QuantumCircuit.runTrajectories(noise:shots:) -> SimulationResult`: Monte-Carlo sampling that converges to the same probabilities.

## StateTomography
`public enum StateTomography` (`StateTomography.swift`), a namespace of static functions:
- `estimate(qubit:result:) -> Double`: (N₀ − N₁)/N from a result already measured in the chosen basis.
- `estimateBlochVector(of circuit:qubit:shots:) -> (x:, y:, z:)`: measures in X, Y and Z (`3 · shots` in total) without changing the circuit.
- `reconstructSingleQubit(x:y:z:tolerance: = 1e-9) -> (vector:, isPhysical: Bool)`: reports whether |r| ≤ 1. A pure state's estimate lands outside the ball about half the time, as page `22Tomography` shows.
- `clampToPhysical(_:)`: rescales r to r/|r| when |r| > 1. This is a simple rescale, not maximum-likelihood estimation.

## PauliBasis, PauliString and Hamiltonian
- `public enum PauliBasis: Character, CaseIterable`: `.x`, `.y`, `.z`, with raw values `"X"`, `"Y"`, `"Z"`.
- `public struct PauliString: Equatable, Hashable`: coefficient · P₀ ⊗ … ⊗ Pₙ₋₁, qubit 0 leftmost.
  - `init(_ label: String, coefficient: Double = 1)` (e.g. `"ZI"`) and `init(labels: [PauliBasis?], coefficient:)`, where `nil` means I.
  - `labels`, `coefficient` (real, so the matrix is Hermitian), `qubits`, `activeQubits`, `label`, `matrix`.
  - `expectation(_ state:) -> Double`: computed in O(2ⁿ) without building the matrix.
  - `isQubitWiseCommuting(with:) -> Bool`.
- `public struct Hamiltonian: Equatable`: Σ terms.
  - `init(_ terms: [PauliString])`: at least one term, all on the same number of qubits. Duplicate labels are not merged.
  - `terms`, `qubits`, `matrix`, and `expectation(_ state:) -> Double`.
  - `trotterCircuit(time:steps:order: = 1) -> QuantumCircuit`: a new circuit for e^(−iHt). `order` is 1 (Lie–Trotter) or 2 (Strang/Suzuki).
  - `commutingGroups() -> [[PauliString]]`: a greedy grouping into qubit-wise-commuting sets. Page 23's H₂ terms `II, ZI, IZ, ZZ, YY, XX` give three groups.
- On `QuantumCircuit`:
  - `measureExpectation(of: PauliString, shots:)` and `measureExpectation(of: Hamiltonian, shots:)`: shot estimates. The `Hamiltonian` version spends `shots` once per commuting group.
  - `evolve(_ hamiltonian:time:steps:order:)`: appends the Trotter steps to an existing circuit, applying terms in their listed order.

Page 23's Hamiltonian in library form:
```swift
let h2 = Hamiltonian([
    PauliString("II", coefficient: -0.4804), PauliString("ZI", coefficient: 0.3435),
    PauliString("IZ", coefficient: -0.4347), PauliString("ZZ", coefficient: 0.5716),
    PauliString("YY", coefficient: 0.0910),  PauliString("XX", coefficient: 0.0910)
])
```

## ParameterShift and GradientDescent
`ParameterShift.swift`:
- `ParameterShift.gradient(at parameters: [Double], shift: Double = .pi / 2, _ cost: ([Double]) -> Double) -> [Double]`: [cost(θ + s·eₖ) − cost(θ − s·eₖ)] / (2 sin s) for each k. Exact when every parameter is the angle of one e^(−iθP/2) rotation (`rx`, `ry`, `rz`, `rzz`, `rxx`, `ryy`, `pauliRotation`). Traps if `shift` is a multiple of π.
- `ParameterShift.gradient(of hamiltonian:at:shift:ansatz: ([Double]) -> QuantumCircuit) -> [Double]`: the same, with cost `hamiltonian.expectation(ansatz(θ).run())`.
- `GradientDescent.minimize(initial:learningRate: = 0.1, maxIterations: = 200, tolerance: = 1e-10, cost:gradient: = nil) -> GradientDescent.Result`: fixed-step descent. It stops when the gradient norm is below `tolerance` or after `maxIterations` steps, and uses the parameter-shift gradient of `cost` when `gradient` is `nil`.
- `GradientDescent.Result`: `parameters`, `value`, `history` (cost at each visited point, starting with `initial`), `parameterHistory`, `iterations` and `converged`.

## Gotchas
- `DensityMatrix.apply(_:)` returns a new value, unlike the mutating `StateVector.apply(_:)`, so write `rho = rho.apply(U)`.
- `PauliString` coefficients are real. A complex-weighted term has to be built as a `Matrix`.
- `evolve` and `trotterCircuit` keep the order the terms are listed in. Grouping first with `Hamiltonian(h.commutingGroups().flatMap { $0 })` changes the finite-step Trotter error.

## Not provided
- Multi-qubit tomography or maximum-likelihood reconstruction.
- Correlated multi-qubit noise: `NoiseModel` applies 2×2 channels qubit by qubit.
- Optimizers other than plain gradient descent (no momentum, line search, COBYLA or Nelder–Mead).
