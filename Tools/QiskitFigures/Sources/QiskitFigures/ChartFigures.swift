import SwiftUI
import SwiftQiskit
import SwiftQiskitViews

extension Figures {
    /// Charts with no random content, so the exported files are the same on every run.
    @MainActor public static var charts: [Figure] {
        [
            // Page 20: E(0, θ) = cos θ for a Bell pair against the best local model.
            Figure(name: "chsh-correlator", group: "chart") {
                let quantumCurve = (0...64).map { i -> CGPoint in
                    let t = Double.pi * Double(i) / 64
                    return CGPoint(x: t, y: cos(t))
                }
                let classicalLine = [CGPoint(x: 0, y: 1), CGPoint(x: Double.pi, y: -1)]
                return AnyView(
                    CHSHChartView(
                        title: "E(θ) for a Bell pair vs. the best local model",
                        xRange: 0...Double.pi,
                        yRange: -1.1...1.1,
                        series: [
                            CHSHChartView.Series(label: "quantum cos θ", color: .blue, points: quantumCurve, isLine: true),
                            CHSHChartView.Series(label: "classical 1 − 2θ/π", color: .red, points: classicalLine, isLine: true)
                        ]
                    )
                )
            }
        ]
    }
}
