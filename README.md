# SwiftQiskitPlaygrounds

Xcode playground pages for [SwiftQiskit](https://github.com/SwiftProjectOrganization/SwiftQiskit),
a Swift quantum-circuit simulator. The library is used as a remote Swift package
(currently resolved to 0.8.1).

**Playground pages 03–<50 are based on the introductory documents in
[SwiftQiskitApp](https://github.com/SwiftProjectOrganization/SwiftQiskitApp)**
(`Docs/Introduction/`). For example, `04Dirac` follows `04-DiracNotation.md`.

## Requirements
- A Mac with Xcode and the macOS 27 SDK (the project's deployment target is macOS 27.0).
- Network access the first time, so Xcode can fetch the SwiftQiskit package.

## Running the playgrounds
1. Open `SwiftQiskitPlaygrounds.xcodeproj` (not the `.playground` on its own), so the
   SwiftQiskit package is resolved.
2. Select the `PlaygroundDeps` scheme with **My Mac** as the run destination, then build (⌘B).
   `PlaygroundDeps` links `SwiftQiskit` and `SwiftQiskitViews`, which the pages import. The
   playground is set to build the active scheme (`buildActiveScheme='true'`).
3. Open a page under `SwiftQiskitPlaygrounds.playground/Pages/` and run it
   (**Editor ▸ Execute Playground**, or the run button next to a line).
4. Use **Editor ▸ Show Rendered Markup** to read the page text, and open the live view
   to see SwiftUI output such as the Bloch sphere.

### Troubleshooting
- `No such module 'SwiftQiskit'`: build the `PlaygroundDeps` scheme first. If that doesn't
  help, use **Product ▸ Clean Build Folder** and build again.
- Package problems: **File ▸ Packages ▸ Resolve Package Versions**, or
  **Update to Latest Package Versions**.

## Pages
Pages are chained with Previous/Next links and live in
`SwiftQiskitPlaygrounds.playground/Pages/`.

| Page | Topic |
|------|-------|
| `01Matrices` | Matrix and `GenericMatrix` arithmetic (math warm-up) |
| `02Complex` | `Complex` arithmetic (math warm-up) |

Pages 03–26 follow the SwiftQiskitApp introduction, one page per chapter (Chapters 5 and 6
share `06BlochSpheres`).

| Page | Topic |
|------|-------|
| `03Qubits` | Single-qubit states and Bloch sphere views |
| `04Dirac` | Dirac notation, `Ket`/`Bra`, and expectation values |
| `05BasesTransformation` | Changing basis |
| `06BlochSpheres` | The Bloch sphere in 2D and 3D: canonical states, projections, θ/φ |
| `07Gates` | Applying a gate the textbook way, with `I ⊗ … ⊗ U ⊗ … ⊗ I` |
| `08Interference` | Phase, interference, and why Z hides |
| `09Measurement` | Measurement, shots, and statistics |
| `10Superposition` | Superposition across a register |
| `11TensorProducts` | Tensor products and composite systems |
| `12Entanglement` | Entanglement: Bell and GHZ states |
| `13Deutsch` | Oracles and phase kickback: Deutsch's algorithm |
| `14DeutschJozsa` | Deutsch–Jozsa and Bernstein–Vazirani: one query, n qubits |
| `15Grover` | Grover's search: oracle, diffusion, over-rotation, CCZ from T gates |
| `16QFT` | The quantum Fourier transform and phase estimation |
| `17Shor` | Shor's algorithm compiled for N = 15: order finding and the a = 14 failure |
| `18Teleportation` | Teleportation (deferred measurement) and superdense coding |
| `19ErrorCorrection` | The 3-qubit bit-flip code: syndromes, correction, and where it breaks |
| `20CHSH` | The CHSH inequality: classical bound 2, a Bell pair at 2√2, and the plotted gap |
| `21Noise` | Density matrices, Kraus channels, coherence decay, and entanglement entropy |
| `22Tomography` | State tomography from shots: basis rotations, 1/√N error, and unphysical estimates |
| `23VQE` | VQE for H₂: a one-parameter ansatz, parameter-shift gradients, and gradient descent |
| `24Trotter` | Hamiltonian simulation: an `expm` ground truth and first- vs second-order Trotter error |
| `25QuantumWalks` | Discrete-time quantum walks: ballistic spreading and coin-phase symmetry |
| `26TensorDiagrams` | Circuits as tensor networks: `TensorNetwork`, `contract()` vs `run()` |

Extra pages:

| Page | Topic |
|------|-------|
| `50StateVectorCPU` | Applying gates directly to a state vector, without building 2ⁿ × 2ⁿ matrices |

## API documentation
The `Documentation/` folder describes the SwiftQiskit API used by the pages, plus (in 09) the
library versions of the tools pages 21–24 build by hand:

| Document | Covers |
|----------|--------|
| [01-ComplexAPI.md](Documentation/01-ComplexAPI.md) | `Complex`: properties, constants, arithmetic |
| [02-MatrixAPI.md](Documentation/02-MatrixAPI.md) | `Matrix` / `GenericMatrix`: initializers, arithmetic, adjoint, trace |
| [03-StateVectorAPI.md](Documentation/03-StateVectorAPI.md) | `StateVector`: amplitudes, probabilities, gates, measurement |
| [04-DiracAPI.md](Documentation/04-DiracAPI.md) | `Ket`, `Bra`, the `†` operator, inner/outer products, expectation values, `⊗` |
| [05-QuantumCircuitAPI.md](Documentation/05-QuantumCircuitAPI.md) | `QuantumCircuit`: gate methods, `run()`, shot and basis measurement; `SimulationResult` |
| [06-GatesAPI.md](Documentation/06-GatesAPI.md) | Gate matrices (`PauliXGate`, `RXGate`, `CNOTGate`, …) and `deg2rad`/`rad2deg` |
| [07-TensorNetworkAPI.md](Documentation/07-TensorNetworkAPI.md) | `TensorNetwork`: nodes, edges, and `contract()` as a check on `run()` |
| [08-ViewsAPI.md](Documentation/08-ViewsAPI.md) | `CHSHChartView` and `TensorNetworkView` live views |
| [09-NoiseTomographyVariationalAPI.md](Documentation/09-NoiseTomographyVariationalAPI.md) | `DensityMatrix`, Kraus channels and noise, `StateTomography`, `PauliString`/`Hamiltonian`, parameter shift and gradient descent |

For the full library, see the [SwiftQiskit repository](https://github.com/SwiftProjectOrganization/SwiftQiskit).

## Repository layout
| Path | Contents |
|------|----------|
| `SwiftQiskitPlaygrounds.xcodeproj` | Xcode project with the SwiftQiskit package dependency |
| `SwiftQiskitPlaygrounds.playground` | The playground pages |
| `PlaygroundDeps/` | Framework target that links `SwiftQiskit` and `SwiftQiskitViews` |
| `Documentation/` | API reference documents |
