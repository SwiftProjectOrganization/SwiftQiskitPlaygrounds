import SwiftUI
import SwiftQiskitViews

/// Bloch sphere rendered as a 2D orthographic projection.
/// Projection: y → right, z → up, x → toward the viewer,
/// drawn obliquely toward the lower-left (foreshortened).
public struct BlochSphereView: View {

    let label: String
    let bloch: BlochVector
    /// Side length of the square canvas, in points
    let size: CGFloat

    public init(label: String, bloch: BlochVector, size: CGFloat = 220) {
        self.label = label
        self.bloch = bloch
        self.size = size
    }

    /// Foreshortening factor for the x-axis (depth)
    private let depth = 0.5 * sqrt(0.5)

    public var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.headline)

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 24

                drawSphere(context, center: center, radius: radius)
                drawAxes(context, center: center, radius: radius)
                drawStateVector(context, center: center, radius: radius)
            }
            .frame(width: size, height: size)

            Text(readout)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var readout: String {
        String(
            format: "x %+.3f  y %+.3f  z %+.3f\nθ %.3f rad  φ %.3f rad",
            bloch.x, bloch.y, bloch.z, bloch.theta, bloch.phi
        )
    }

    /// Project a 3D point on the unit sphere to canvas coordinates
    private func project(
        _ x: Double, _ y: Double, _ z: Double,
        center: CGPoint, radius: Double
    ) -> CGPoint {
        CGPoint(
            x: center.x + (y - x * depth) * radius,
            y: center.y - (z - x * depth) * radius
        )
    }

    private func drawSphere(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        // Sphere outline
        let outline = Path(
            ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            )
        )
        context.stroke(outline, with: .color(.primary.opacity(0.6)), lineWidth: 1)

        // Equator (flattened, dashed)
        let equator = Path(
            ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius * depth,
                width: radius * 2, height: radius * depth * 2
            )
        )
        context.stroke(
            equator,
            with: .color(.secondary.opacity(0.5)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
        )
    }

    private func drawAxes(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        let axes: [(x: Double, y: Double, z: Double, label: String)] = [
            (1, 0, 0, "x"),
            (0, 1, 0, "y"),
            (0, 0, 1, "|0⟩"),
            (0, 0, -1, "|1⟩")
        ]

        for axis in axes {
            let tip = project(axis.x, axis.y, axis.z, center: center, radius: radius)
            let tail = project(-axis.x, -axis.y, -axis.z, center: center, radius: radius)

            var line = Path()
            line.move(to: tail)
            line.addLine(to: tip)
            context.stroke(line, with: .color(.secondary.opacity(0.5)), lineWidth: 0.5)

            // Label just beyond the axis tip
            let labelPoint = project(
                axis.x * 1.15, axis.y * 1.15, axis.z * 1.15,
                center: center, radius: radius
            )
            context.draw(
                Text(axis.label).font(.caption2).foregroundStyle(.secondary),
                at: labelPoint
            )
        }
    }

    private func drawStateVector(_ context: GraphicsContext, center: CGPoint, radius: Double) {
        let tip = project(bloch.x, bloch.y, bloch.z, center: center, radius: radius)

        var arrow = Path()
        arrow.move(to: center)
        arrow.addLine(to: tip)
        context.stroke(arrow, with: .color(.red), lineWidth: 2)

        let dot = Path(
            ellipseIn: CGRect(x: tip.x - 4, y: tip.y - 4, width: 8, height: 8)
        )
        context.fill(dot, with: .color(.red))
    }
}
