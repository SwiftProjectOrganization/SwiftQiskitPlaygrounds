import SwiftUI
import SwiftQiskit
import SwiftQiskitViews

extension Figures {
    /// Tensor network diagrams of the circuits on page 26.
    @MainActor public static var tensors: [Figure] {
        func figure(_ name: String, _ title: String, _ build: @escaping @Sendable () -> QuantumCircuit) -> Figure {
            Figure(name: name, group: "tensor") {
                AnyView(TensorNetworkView(TensorNetwork(build()), title: title))
            }
        }
        return [
            figure("tensor-bell", "Bell pair: h(0); cx(0,1)") {
                let circuit = QuantumCircuit(qubits: 2)
                circuit.h(0)
                circuit.cx(0, 1)
                return circuit
            },
            figure("tensor-ghz", "GHZ: the second CX spans q0–q2, q1 crosses it dashed") {
                let circuit = QuantumCircuit(qubits: 3)
                circuit.h(0)
                circuit.cx(0, 1)
                circuit.cx(0, 2)
                return circuit
            },
            figure("tensor-rzz", "rzz(0.7) = CX; RZ; CX") {
                let circuit = QuantumCircuit(qubits: 2)
                circuit.rzz(0.7, 0, 1)
                return circuit
            }
        ]
    }
}
