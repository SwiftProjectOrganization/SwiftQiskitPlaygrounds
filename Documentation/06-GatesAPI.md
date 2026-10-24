# Gates API

Each gate is a caseless `public enum` in `SwiftQiskit/Sources/SwiftQiskit/Gates/` that only provides matrices. The `QuantumCircuit` methods (`05-QuantumCircuitAPI.md`) use these same matrices. Pages use the enums directly when they build operators the textbook way, e.g. `ψ† * PauliZGate.matrix * ψ` or `I ⊗ HadamardGate.matrix`. All matrices are `Matrix` (`02-MatrixAPI.md`); angles are in radians.

## Fixed single-qubit gates (`static let matrix`)
- `PauliXGate`, `PauliYGate`, `PauliZGate`: X, Y = [[0, −i], [i, 0]], Z.
- `HadamardGate`: (1/√2)·[[1, 1], [1, −1]].
- `SGate` = diag(1, i), `SDaggerGate` = diag(1, −i).
- `TGate` = diag(1, e^(iπ/4)), `TDaggerGate` = its adjoint.

## Parameterised single-qubit gates (`static func matrix(theta:)`)
- `PhaseGate`: P(θ) = diag(1, e^(iθ)). `TGate` is `PhaseGate.matrix(theta: .pi / 4)`.
- `RXGate`: [[cos(θ/2), −i·sin(θ/2)], [−i·sin(θ/2), cos(θ/2)]] = e^(−iθX/2).
- `RYGate`: [[cos(θ/2), −sin(θ/2)], [sin(θ/2), cos(θ/2)]] (real) = e^(−iθY/2).
- `RZGate`: diag(e^(−iθ/2), e^(iθ/2)) = e^(−iθZ/2). Equal to P(θ) up to the global phase e^(−iθ/2).

## Two-qubit rotations (`static func matrix(theta:)`, 4×4)
- `RZZGate`: e^(−iθZ⊗Z/2) = diag(e^(−iθ/2), e^(iθ/2), e^(iθ/2), e^(−iθ/2)). Exactly `cx(0,1); rz(θ,1); cx(0,1)`, as page `24Trotter` checks.
- `RXXGate`: e^(−iθX⊗X/2) = cos(θ/2)·I − i·sin(θ/2)·X⊗X.
- `RYYGate`: e^(−iθY⊗Y/2) = cos(θ/2)·I − i·sin(θ/2)·Y⊗Y.

## Controlled and permutation gates
The `static let matrix` is the smallest form: control(s) first, target last. The `matrix(qubits:…)` factory builds the full 2ⁿ×2ⁿ matrix for any qubit positions and traps on out-of-range or repeated indices.

| Type | `matrix` | Full-register factory |
|------|----------|-----------------------|
| `CNOTGate` | 4×4, control 0 → target 1 | `matrix(qubits:control:target:)` |
| `ControlledYGate` | 4×4 | `matrix(qubits:control:target:)` |
| `ControlledZGate` | diag(1, 1, 1, −1) | `matrix(qubits:control:target:)` |
| `SwapGate` | 4×4 | `matrix(qubits:q0:q1:)` |
| `ToffoliGate` | 8×8, controls 0, 1 → target 2 | `matrix(qubits:control1:control2:target:)` |
| `MultiControlledXGate` | — | `matrix(qubits:controls:target:)` |
| `MultiControlledYGate` | — | `matrix(qubits:controls:target:)` |
| `MultiControlledZGate` | — | `matrix(qubits:controls:target:)` |

CNOT, Swap, Toffoli and multi-controlled X are built with `Matrix.permutation`, so `StateVector.apply(_:)` takes its fast permutation path for them.

## Angle helpers (`Utils/Angles.swift`)
- `deg2rad(_ degrees: Double) -> Double` and `rad2deg(_ radians: Double) -> Double`: global functions.

## Gotchas
- Qubit 0 is the most-significant factor: `CNOTGate.matrix(qubits: 2, control: 0, target: 1)` equals `CNOTGate.matrix`, and `I ⊗ U` acts on qubit 1.
- The single-qubit `matrix` values are 2×2. To use one inside an n-qubit register with `StateVector.apply(_:)`, tensor it with identities, or use a `QuantumCircuit` method, which places it for you.
- `RZGate` and `PhaseGate` differ by a global phase: the same measurement statistics, but not equal matrices.

## Not provided
- A U3/general single-qubit gate, or controlled versions of arbitrary gates. Use `apply(_:)` with a hand-built `Matrix`, or `Matrix.expm` (`02-MatrixAPI.md`) for e^(−iθH).
