# QuantumCircuit API

`QuantumCircuit` is declared in `SwiftQiskit/Sources/SwiftQiskit/Circuit/QuantumCircuit.swift` as `public final class QuantumCircuit`. A circuit records operations; nothing is simulated until `run()` or one of the measure methods is called. `SimulationResult` (`Quantum/SimulationResult.swift`) holds shot counts. Pages 13–26 build almost everything with these two types.

## Stored property
- `public let qubits: Int`: the register size, fixed at construction.

## Initializer
- `init(qubits:)`: an empty circuit on |0…0⟩. Traps unless `0 < qubits <= 30`.

## Single-qubit gates
Each takes the qubit index as its last unlabelled argument. Angles are in radians (see `06-GatesAPI.md` for the matrices).
- `h(_:)`, `x(_:)`, `y(_:)`, `z(_:)`.
- `s(_:)` and `sdg(_:)`: phase ±π/2. `t(_:)` and `tdg(_:)`: phase ±π/4.
- `p(_ theta:_ qubit:)`: the phase gate P(θ) = diag(1, e^(iθ)).
- `rx(_ theta:_ qubit:)`, `ry(_ theta:_ qubit:)`, `rz(_ theta:_ qubit:)`: rotations e^(−iθσ/2).

## Multi-qubit gates
Any distinct qubits may be used; they need not be adjacent.
- `cx(_ control:_ target:)`, `cy(_:_:)`, `cz(_:_:)` (symmetric), `swap(_:_:)`.
- `ccx(_ control1:_ control2:_ target:)`: Toffoli.
- `mcx(_ controls: [Int], _ target:)`, `mcy(_:_:)`, `mcz(_:_:)`: any number of controls. An empty `controls` is the plain `x`/`y`/`z`.
- `rzz(_ theta:_ q0:_ q1:)`, `rxx(_:_:_:)`, `ryy(_:_:_:)`: e^(−iθP⊗P/2). These are recorded as their decomposition, so `rzz` appears as `cx; rz; cx` (see page `26TensorDiagrams`).
- `pauliRotation(_ pauli: String, theta:)`: e^(−iθP/2) for a Pauli string such as `"XIZ"`, one character per qubit. Built from basis changes, a CNOT staircase and one `rz`. An all-`I` string records a global phase.
- `increment(register:controlledBy:)` and `decrement(register:controlledBy:)`: ripple-carry ±1 on a register stored most-significant qubit first, optionally controlled. Built from `mcx`; traps if the register is empty, has repeats, or contains the control.

## Arbitrary operators
- `apply(_ matrix: Matrix)`: records a full 2ⁿ×2ⁿ operator. Traps if the size doesn't match. It is recorded as touching every qubit, so a noise model applies noise to all of them and a `TensorNetwork` shows it as one node across the whole register (label `"U"`).

## Running
- `run() -> StateVector`: simulates from |0…0⟩ and returns the final state. Each call starts over; the circuit isn't changed.
- `runAndMeasure() -> Int`: `run()` followed by one `StateVector.measure()`; returns the basis index.
- `measure(shots:) -> SimulationResult`: runs once and draws `shots` samples from the final distribution. Traps unless `shots > 0`.
- `measure(shots:basis: [PauliBasis]) -> SimulationResult`: measures each qubit in its own X, Y or Z basis, one entry per qubit. Rotates a copy of the state; the circuit is not modified.
- `rotateToZ(_ basis: PauliBasis, _ qubit:)`: appends the rotation that maps `basis` onto Z (`h` for X, `sdg; h` for Y, nothing for Z). Unlike `measure(shots:basis:)`, this does change the circuit.

## Noise, expectation values and time evolution
Covered in `09-NoiseTomographyVariationalAPI.md`:
- `runDensityMatrix(noise:) -> DensityMatrix` and `runTrajectories(noise:shots:) -> SimulationResult`.
- `measureExpectation(of: PauliString, shots:)` and `measureExpectation(of: Hamiltonian, shots:)`.
- `evolve(_ hamiltonian:time:steps:order:)`: appends a first- or second-order Trotter circuit.

## SimulationResult
`public struct SimulationResult`:
- `shots: Int` and `counts: [String: Int]`. Keys are bit strings zero-padded to the register width, qubit 0 first; only observed outcomes appear.
- `sortedCounts: [(state: String, count: Int)]`: `counts` sorted by key.
- `marginalCounts(over qubits: [Int]) -> [String: Int]`: counts for a subset of qubits, with key bits in the order the qubits are listed.
- `parityExpectation(qubits: [Int]) -> Double`: the average of (−1)^(number of 1s on `qubits`), i.e. the shot estimate of ⟨Z⊗…⊗Z⟩ on those qubits.

## Gotchas
- `QuantumCircuit` is a class: `let qc = QuantumCircuit(qubits: 2)` can still have gates added, and two variables can share one circuit. Build a new circuit for each variant.
- Qubit 0 is the most-significant (leftmost) bit, in `counts` keys, in `StateVector` indices and in `|01⟩` labels.
- `counts` keys are zero-padded, but `StateVector.description` labels are not (see `04-DiracAPI.md`).
- Gates record their small local matrices; full 2ⁿ×2ⁿ matrices are only built for `apply(_:)` and `runDensityMatrix`.

## Not provided
- Mid-circuit measurement or classical control. Page `18Teleportation` uses deferred measurement (controlled gates) instead.
- Removing or inspecting recorded operations from outside the package. Use `TensorNetwork` (`07-TensorNetworkAPI.md`) to see what was recorded.
