# TensorNetwork API

`TensorNetwork` is declared in `SwiftQiskit/Sources/SwiftQiskit/Circuit/TensorNetwork.swift` as `public struct TensorNetwork`. It turns a `QuantumCircuit` (`05-QuantumCircuitAPI.md`) into nodes and edges: one input per qubit, one node per recorded gate, one output per qubit, and one edge per wire segment. `contract()` evaluates the network from the small gate tensors alone, so comparing it with `run()` checks both. Used by page `26TensorDiagrams`; draw it with `TensorNetworkView` (`08-ViewsAPI.md`).

## Nested types
- `enum Kind: Equatable`: `.input`, `.gate(String)` and `.output`. The string is the circuit's gate label: `"H"`, `"CX"`, `"S†"`, `"RX(1.571)"` (angles to three decimals), `"U"` for `apply(_:)`, or `"phase"` for a global phase.
- `struct Node`:
  - `id: Int`.
  - `kind: Kind`.
  - `qubits: [Int]`: the qubits the node's legs connect to, in the tensor's leg order. Empty only for a `"phase"` node.
  - `column: Int`: its time step for drawing. Gates on disjoint qubits can share a column.
  - `tensor: Matrix`: 2ᵏ×2ᵏ for a gate on k qubits (1×1 for `"phase"`). Inputs hold |0⟩ (2×1) and outputs hold a 2×2 identity; `contract()` ignores both.
- `struct Edge`: `id`, `qubit` (the wire it carries), `from` and `to` (node ids).

## Stored properties
- `qubits: Int`: the circuit's register size.
- `nodes: [Node]`: inputs (column 0), then gates in recorded order, then outputs (final column).
- `edges: [Edge]`.
- `columns: Int`: one past the highest column used.

## Initializer
- `init(_ circuit: QuantumCircuit)`: a snapshot of the operations recorded so far. Gates added to the circuit later don't appear.

## Methods
- `contract() -> StateVector`: starts from |0…0⟩ and applies each gate node's own tensor to the qubits it names, never a 2ⁿ×2ⁿ matrix. For a circuit of gates it should match `circuit.run()` to floating-point precision.

## Gotchas
- `rzz`, `rxx`, `ryy` and `pauliRotation` are recorded as their decomposition, so `rzz(θ, 0, 1)` shows up as three nodes, `CX`, `RZ(θ)`, `CX`.
- A circuit operator added with `apply(_:)` becomes one `"U"` node with a leg on every qubit, holding the full matrix.
- There is one edge per gate leg plus one per output, so a CX contributes two edges and `edges.count` is the total leg count of all gates plus `qubits`.

## Not provided
- Choosing a contraction order, or contracting to anything other than the final state vector.
- Building a network by hand: nodes and edges are read-only, and the only initializer takes a circuit.
