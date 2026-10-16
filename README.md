# SwiftQiskitPlaygrounds

Xcode playground pages for [SwiftQiskit](https://github.com/SwiftProjectOrganization/SwiftQiskit),
using the library as a remote Swift package (from 0.7.2).

Pages: `01Qubits`, `02StateVectorCPU` (formerly `42StateVectorCPU`), `03ApplyingGates`.

## Running
1. Open `SwiftQiskitPlaygrounds.xcodeproj`.
2. Select the `PlaygroundDeps` scheme (My Mac) and build. It links `SwiftQiskit` and
   `SwiftQiskitViews`, which the playground imports (`buildActiveScheme='true'`).
3. Open a page under `SwiftQiskitPlaygrounds.playground/Pages/` and run it.

Note: `01Qubits` links to `PlaygroundDocs/` guides that still live in the SwiftQiskit repo.
