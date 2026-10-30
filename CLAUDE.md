# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Overview

SwiftQiskitPlaygrounds is a set of Xcode playground pages that exercise the `SwiftQiskit`
quantum-circuit simulator. Pages `01`–`02` accompany Chapter 2 (`01Matrices` is a real-valued
`GenericMatrix` warm-up, `02ComplexAndMatrices` follows the chapter); pages
`03`–`26` follow the remaining chapters of the SwiftQiskitApp introduction
(`../SwiftQiskitApp/Docs/Introduction/`), one page per chapter (Chapters 5 and 6 share
`06BlochSpheres`); `50StateVectorCPU` is an extra page. All simulation lives in the
`SwiftQiskit` package; this repository contains only pages, a small framework target, and
API reference documents.

## Relationship to the SwiftQiskit package

This project depends on **`SwiftQiskit` as a remote package** (currently resolved to `0.9.1`).
The package ships two products, `SwiftQiskit` and `SwiftQiskitViews` (SwiftUI views such as
`BlochVector`, `CHSHChartView`, `TensorNetworkView`). The `PlaygroundDeps` framework target
links both, and the pages import them:

```swift
import SwiftQiskit
import SwiftQiskitViews
```

**Editing the package in tandem with these pages:** package edits don't reach this project
until they're committed, tagged, and pulled in via File > Packages > Update to Latest Package
Versions. For tandem development, drag a local `../SwiftQiskit` checkout into this project's
workspace — a local package overrides a remote dependency of the same name. Remove the
override when done.

## Build & Run

Prefer the `xcode-tools` MCP tools (`BuildProject`, `XcodeRefreshCodeIssuesInFile`,
`RunCodeSnippet`).

- Open `SwiftQiskitPlaygrounds.xcodeproj`, not the `.playground` on its own, so the package
  resolves.
- Build the **`PlaygroundDeps`** scheme with **My Mac** as the run destination before running
  any page. The playground has `buildActiveScheme='true'`.
- Deployment target is macOS 27.0.
- `No such module 'SwiftQiskit'`: build `PlaygroundDeps` first; if that fails, Clean Build
  Folder and rebuild. For package problems use File > Packages > Resolve Package Versions.
- There are no unit tests in this repository; a page is verified by building and executing it.

## Repository layout

| Path | Contents |
|---|---|
| `SwiftQiskitPlaygrounds.xcodeproj` | Xcode project with the SwiftQiskit package dependency |
| `SwiftQiskitPlaygrounds.playground/Pages/` | The pages, `NNName.xcplaygroundpage/Contents.swift` |
| `PlaygroundDeps/` | Framework target that links `SwiftQiskit` and `SwiftQiskitViews` |
| `Documentation/` | API reference documents `01`–`09` |
| `Tools/` | Command-line helpers; `ExportBlochSphere` writes the Bloch sphere PNG and PDF (page 51) |
| `README.md` | Overview, page table, API document table |

## Page conventions

- A page is `NNName.xcplaygroundpage/Contents.swift`; numbering follows the introduction
  chapter it accompanies.
- Each page starts with `//: [Previous](@previous)`, then a `/*: # Title ... */` markup block
  (bullet summary of the idea, any stated limits, and a closing line
  `Follows Chapter N of the SwiftQiskitApp introduction.`), then imports and code, and ends
  with `//: [Next](@next)`.
- SwiftUI output (charts, Bloch spheres) is shown through the playground live view.
- Prefer library APIs (`ccx`, `mcz`, `Matrix.expm`, `TensorNetwork`, ...) over hand-built
  versions once the package provides them; a page may still build a tool by hand when the
  point of the page is to show how it works.
- Adding or renaming a page: update the page table in `README.md`, and update
  `Documentation/` if the page uses API not yet described there.

## Conventions & gotchas

- **Qubit indexing:** qubit 0 is the most-significant (leftmost) bit — same convention as the
  package.
- **Measurement is probabilistic:** shot histograms jitter between runs; don't expect exact
  ratios.
- **Dense matrices:** pages that build 2ⁿ × 2ⁿ matrices (`expm`, textbook gate application)
  only scale to a few qubits; say so in the page's markup.
- Style: 4-space indent, PascalCase types, camelCase members, no force unwrapping, no Combine
  (prefer async/await and Observation).

## Tool hints

When working in Claude Code with Sonnet tools, read-only permission is always granted for
the `SwiftQiskit`, `SwiftQiskitApp` and `SwiftQiskitPlaygrounds` repositories
(`/Users/rob/Projects/Swift/<name>`). Reading and searching them needs no confirmation:

- Read, Grep and Glob, and the `xcode-tools` read tools (`XcodeRead`, `XcodeGrep`,
  `XcodeGlob`, `XcodeLS`).
- Read-only shell commands such as `ls`, `cat`, `git status`, `git log`, `git diff` and
  `git show`.

Edits, state-changing builds, commits and pushes still follow the normal confirmation rules.
Use the siblings freely for reference: `../SwiftQiskit` for what the gates compute and the
public API, `../SwiftQiskitApp` for the introduction chapters the pages follow.

## Writing style

The user prefers a sober writing style — plain, measured prose, no hype, no exclamation
marks, no sales-pitch framing. Applies to page markup, `Documentation/`, `README.md`, commit
messages, and PR descriptions.

## Documentation index

- `README.md` — overview, running the playgrounds, page table, API document table.
- `Documentation/01-ComplexAPI.md` — `Complex`, its polar form, and `[Complex]` arithmetic.
- `Documentation/02-MatrixAPI.md` — `Matrix` / `GenericMatrix`.
- `Documentation/03-StateVectorAPI.md` — `StateVector`.
- `Documentation/04-DiracAPI.md` — `Ket`, `Bra`, `†`, inner/outer products, `⊗`.
- `Documentation/05-QuantumCircuitAPI.md` — `QuantumCircuit`, `SimulationResult`.
- `Documentation/06-GatesAPI.md` — gate matrices, `deg2rad`/`rad2deg`.
- `Documentation/07-TensorNetworkAPI.md` — `TensorNetwork`, `contract()`.
- `Documentation/08-ViewsAPI.md` — `CHSHChartView`, `TensorNetworkView`.
- `Documentation/09-NoiseTomographyVariationalAPI.md` — `DensityMatrix`, Kraus channels,
  `StateTomography`, `Hamiltonian`, parameter shift.
- `../SwiftQiskit/CLAUDE.md`, `../SwiftQiskit/README.md`, `../SwiftQiskit/API.md` — the
  simulator itself.
- `../SwiftQiskitApp/INTRODUCTION.md` and `Docs/Introduction/` — the chapters these pages
  accompany.
