# Figures plan (PNG and PDF export)

This document records why and how `Tools/QiskitFigures` exists, so that more figures can be added later.

## Goal

Produce many PNG and PDF figures (Bloch spheres, charts, tensor diagrams) from this repository, using the `writePNG(to:scale:background:)` and `writePDF(to:background:)` methods that SwiftQiskit 0.9.1 adds to `SwiftQiskitViews` views (`ViewExport.swift`).

## Constraint

In an Xcode 27.2 playground, calling `writePNG` or `writePDF` fails with "Failed to load linked library cups of module SwiftUI". Moving the call into the `PlaygroundDeps` framework did not help. A page can show a view in the live view, but the files have to be written by a command-line program.

## Design

Each figure is defined once, in a library that both the playground pages and the export program import.

`Tools/QiskitFigures` is a Swift package with two products:

| Product | Kind | Purpose |
|---|---|---|
| `QiskitFigures` | library | `Figure` (name, group, view), `Figures.all`, `Figures.named(_:)` |
| `ExportFigures` | executable | writes the selected figures as PNG and/or PDF |

The package depends on SwiftQiskit 0.9.1 or later, using the same URL as the Xcode project (`https://github.com/SwiftProjectOrganization/SwiftQiskit.git`) so that one copy resolves.

The Xcode project adds `Tools/QiskitFigures` as a local package, and the `PlaygroundDeps` target links the `QiskitFigures` product. A page can then `import QiskitFigures` and show a figure with `Figures.named("bloch-plus")?.view`.

## Figures

| Group | Names | Source |
|---|---|---|
| `bloch` | `bloch-zero`, `bloch-one`, `bloch-plus`, `bloch-minus`, `bloch-plus-i`, `bloch-minus-i` | `BlochFigures.swift`, `BlochSphereView` with the `Ket` constants |
| `chart` | `chsh-correlator` | `ChartFigures.swift`, page 20 without the 500-shot samples |
| `tensor` | `tensor-bell`, `tensor-ghz`, `tensor-rzz` | `TensorFigures.swift`, circuits from page 26 |

The chart leaves out the sampled series so the exported file is the same on every run. Its quantum curve is cos θ, which page 20 checks against the matrix computation.

To add a figure, add an entry in the matching file. A new kind of figure gets a new file and a new `Figures` property, which `Figures.all` includes.

## Running the exporter

From the repository root:

```
swift run --package-path Tools/QiskitFigures ExportFigures [--list] [--out <folder>] [--format png|pdf|both] [name-or-group ...]
```

- No names exports every figure. A name selects one figure and a group name (`bloch`, `chart`, `tensor`) selects all figures in it.
- The default folder is `~/Documents/QiskitFigures`. It is created if it does not exist, and so is a folder given with `--out`.
- `--format` defaults to `both`. PNG files use scale 2 and a white background.
- An unknown name prints an error and exits with status 1.

The exporter can also be run from Xcode through the `ExportFigures` scheme, with the arguments set in the scheme editor.

## Limits

- Export must run in the command-line tool, not in a page.
- `CHSHChartView` draws no tick labels on its axes, so the chart figure has none either.
- Pages 20 and 26 still build their own views. They can switch to `Figures` later.
- A change to a view in SwiftQiskit reaches the figures only after SwiftQiskit is tagged and `Tools/QiskitFigures/Package.swift` is updated or resolved to it.

## Possible later step

If many more exporters are needed, the figure definitions could move into an executable target of the SwiftQiskit package, next to the views. That requires a SwiftQiskit change, a new tag and a package update here, so it is worth doing only when the figure list outgrows this package.
