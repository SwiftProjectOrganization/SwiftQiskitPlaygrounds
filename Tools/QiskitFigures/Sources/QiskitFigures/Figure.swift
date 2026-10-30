import SwiftUI

/// A named figure: a SwiftUI view that a playground page can show and `ExportFigures` can
/// write as PNG and PDF.
public struct Figure: Sendable {
    /// File stem used by the exporter, for example `bloch-plus`.
    public let name: String
    /// `bloch`, `chart` or `tensor`.
    public let group: String
    private let make: @MainActor @Sendable () -> AnyView

    init(name: String, group: String, make: @escaping @MainActor @Sendable () -> AnyView) {
        self.name = name
        self.group = group
        self.make = make
    }

    @MainActor public var view: AnyView { make() }
}

public enum Figures {
    /// Every figure, in group order.
    @MainActor public static var all: [Figure] { bloch + charts + tensors }

    /// The figure called `name`, if there is one.
    @MainActor public static func named(_ name: String) -> Figure? {
        all.first { $0.name == name }
    }
}
