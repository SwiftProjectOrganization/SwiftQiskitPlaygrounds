# Views API (charts and tensor diagrams)

The `SwiftQiskitViews` library (`SwiftQiskit/Sources/SwiftQiskitViews/`) provides SwiftUI views for the pages' live views. This document covers the two used by pages 20, 23, 24 and 26: `CHSHChartView` and `TensorNetworkView`. Both are stateless `public struct`s that conform to `View`, so a page can create one directly and pass it to `PlaygroundPage.current.setLiveView(_:)`. The Bloch sphere views used by pages 03 and 06 are not covered here.

## CHSHChartView
`CHSHChartView.swift`: despite its name, a general 2D line and scatter chart. Page `20CHSH` uses it for correlation curves, `23VQE` for the energy landscape and descent steps, and `24Trotter` for ⟨Z₀⟩(t).

### Initializer
- `init(title: String, xRange: ClosedRange<Double>, yRange: ClosedRange<Double>, series: [Series], size: CGSize = CGSize(width: 480, height: 300))`.

### `CHSHChartView.Series`
- `init(label: String, color: Color, points: [CGPoint], isLine: Bool)`.
- `isLine: true` draws a connected curve, with `points` assumed sorted by x. `isLine: false` draws one dot per point, e.g. shot-sampled values.
- The properties are internal; a `Series` can be created but not read back.

### Example
```swift
let curve = (0...40).map { i -> CGPoint in
    let x = Double.pi * Double(i) / 40
    return CGPoint(x: x, y: cos(x))
}
PlaygroundPage.current.setLiveView(
    CHSHChartView(
        title: "cos θ",
        xRange: 0...Double.pi,
        yRange: -1...1,
        series: [CHSHChartView.Series(label: "cos θ", color: .blue, points: curve, isLine: true)]
    )
    .padding()
)
```

## TensorNetworkView
`TensorNetworkView.swift`: draws a `TensorNetwork` (`07-TensorNetworkAPI.md`) aligned with the circuit. Qubit wires run left to right, with |0⟩ caps on the left and open output legs on the right, and each gate is a labelled box in its time column. Used by page `26TensorDiagrams`.

### Initializer
- `init(_ network: TensorNetwork, title: String = "Tensor Network", size: CGSize? = nil)`. With `size: nil`, the size is computed from `network.columns` and `network.qubits`.

### Drawing details
- A multi-qubit gate between non-adjacent qubits spans the wires in between. Wires that pass under the box without connecting to it are redrawn dashed.
- If the network has a global-phase node (`.gate("phase")`, which has no legs), the view adds a purple "global phase" legend entry and a larger top margin.

## Gotchas
- Import both modules on the page: `import SwiftQiskit` for the data and `import SwiftQiskitViews` for the views. Both are linked by building the `PlaygroundDeps` scheme (see the README).
- `CHSHChartView` maps points linearly into `xRange`/`yRange` and doesn't clip them, so choose ranges that contain the data.
