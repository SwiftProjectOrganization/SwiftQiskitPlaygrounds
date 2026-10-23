//: [Previous](@previous)
/*:
 # Tensor Diagrams

 A second way to read a circuit: not as one big 2ⁿ × 2ⁿ matrix replayed gate by gate, but
 as a graph of small local tensors wired together.

 - A qubit wire is a bond-dimension-2 edge; a k-qubit gate is a node holding a small
   2ᵏ × 2ᵏ tensor, never the full embedded matrix.
 - `TensorNetwork(_:)` builds one `.input` node per qubit, one `.gate` node per recorded
   operation and one `.output` node per qubit.
 - Nodes are scheduled ASAP, so gates on disjoint qubits can share a column.
 - A non-adjacent `cx` spans the rows between its qubits; the skipped wire crosses it dashed.
 - `rzz` is not one node: it unfolds into `CX`, `RZ`, `CX`.
 - A `CP` gate is five primitive gates, visible as five boxes in a row.
 - `contract()` rebuilds the state from the small tensors alone and agrees with `run()`,
   an independent check of both routes.

 Limit: `contract()` still allocates a full `StateVector`, so this page shows the diagram
 and the identity check, not a faster simulator.

 Follows Chapter 26 of the SwiftQiskitApp introduction.
 */

import Foundation
import SwiftUI
import PlaygroundSupport
import SwiftQiskit
import SwiftQiskitViews

// Compares contract() against run() on the full amplitude vector.
func maxAmplitudeError(_ network: TensorNetwork, _ circuit: QuantumCircuit) -> Double {
    let contracted = network.contract()
    let run = circuit.run()
    return (0..<run.dimension).map { (contracted[$0] - run[$0]).magnitude }.max() ?? 0
}

func report(_ name: String, _ network: TensorNetwork, _ circuit: QuantumCircuit) {
    print("\(name): nodes \(network.nodes.count), edges \(network.edges.count), columns \(network.columns), contract() vs run() = \(String(format: "%.2e", maxAmplitudeError(network, circuit)))")
}

func gateNames(_ network: TensorNetwork) -> [String] {
    network.nodes.compactMap { node -> String? in
        guard case .gate(let name) = node.kind else { return nil }
        return name
    }
}

// ------------------------------------------------------------
// §1 — A Bell pair
// ------------------------------------------------------------

let bell = QuantumCircuit(qubits: 2)
bell.h(0)
bell.cx(0, 1)
let bellNetwork = TensorNetwork(bell)
report("Bell pair", bellNetwork, bell)
// 6 nodes (2 inputs, H, CX, 2 outputs) and 5 edges (q0: 2 segments + 1; q1: 1 + 1)

// ------------------------------------------------------------
// §2 — A non-adjacent CX (GHZ)
// ------------------------------------------------------------

let ghz = QuantumCircuit(qubits: 3)
ghz.h(0)
ghz.cx(0, 1)
ghz.cx(0, 2)
let ghzNetwork = TensorNetwork(ghz)
report("GHZ", ghzNetwork, ghz)
// 9 nodes, 8 edges, 5 columns
if let secondCX = ghzNetwork.nodes.first(where: { node in
    if case .gate("CX") = node.kind { return node.qubits == [0, 2] }
    return false
}) {
    print("second CX: qubits \(secondCX.qubits), column \(secondCX.column)")    // [0, 2], 3
}

// ------------------------------------------------------------
// §3 — rzz unfolds into cx; rz; cx
// ------------------------------------------------------------

let zz = QuantumCircuit(qubits: 2)
zz.rzz(0.7, 0, 1)
let zzNetwork = TensorNetwork(zz)
report("rzz(0.7)", zzNetwork, zz)
print("gate nodes:", gateNames(zzNetwork))
// ["CX", "RZ(0.700)", "CX"] — the diagram sees only the primitive gates that were recorded

// ------------------------------------------------------------
// §4 — A 2-qubit QFT ladder
// ------------------------------------------------------------

func cp(_ theta: Double, control: Int, target: Int, on circuit: QuantumCircuit) {
    circuit.p(theta / 2, control)
    circuit.cx(control, target)
    circuit.p(-theta / 2, target)
    circuit.cx(control, target)
    circuit.p(theta / 2, target)
}

let qft = QuantumCircuit(qubits: 2)
qft.h(0)
cp(.pi / 2, control: 0, target: 1, on: qft)
qft.h(1)
let qftNetwork = TensorNetwork(qft)
report("2-qubit QFT", qftNetwork, qft)
// 11 nodes, 11 edges, 9 columns: five boxes for one controlled phase

// ------------------------------------------------------------
// §5 — Disjoint gates share a column
// ------------------------------------------------------------

let parallel = QuantumCircuit(qubits: 2)
parallel.h(0); parallel.h(1); parallel.cx(0, 1)
let parallelNetwork = TensorNetwork(parallel)
report("h(0); h(1); cx(0,1)", parallelNetwork, parallel)
// 7 nodes and 6 edges
for node in parallelNetwork.nodes {
    if case .gate(let name) = node.kind { print("  \(name) on \(node.qubits) at column \(node.column)") }
}
// both H nodes sit in column 1; the CX follows in column 2

// ------------------------------------------------------------
// §6 — Contraction
// ------------------------------------------------------------
// Every network above agreed with run() to machine precision. Here is a random-angle
// circuit as one more check.

let mixed = QuantumCircuit(qubits: 3)
mixed.h(0); mixed.ry(0.9, 1); mixed.cx(0, 2); mixed.rz(0.4, 2); mixed.cx(1, 2); mixed.h(2)
report("mixed 3-qubit circuit", TensorNetwork(mixed), mixed)

// ------------------------------------------------------------
// §7 — Live view
// ------------------------------------------------------------
// The four diagrams stacked. Stateless views (no @State) — required for page code.

PlaygroundPage.current.setLiveView(
    ScrollView([.horizontal, .vertical]) {
        VStack(alignment: .leading, spacing: 24) {
            TensorNetworkView(bellNetwork, title: "Bell pair: h(0); cx(0,1)")
            TensorNetworkView(ghzNetwork, title: "GHZ: the second CX spans q0–q2, q1 crosses it dashed")
            TensorNetworkView(zzNetwork, title: "rzz(0.7) = CX; RZ; CX")
            TensorNetworkView(qftNetwork, title: "2-qubit QFT: h; CP(π/2) as five gates; h")
        }
        .padding()
    }
    .frame(width: 900, height: 640)
)

//: [Next](@next)
