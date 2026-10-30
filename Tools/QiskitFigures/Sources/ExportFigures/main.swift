import Foundation
import SwiftUI
import QiskitFigures
import SwiftQiskitViews

// ExportFigures --list
// ExportFigures [--out <folder>] [--format png|pdf|both] [name-or-group ...]
//
// Writes <name>.png and/or <name>.pdf for the selected figures, or for all of them when no
// name is given. The default folder is ~/Documents/QiskitFigures, created if needed.

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

var folder = FileManager.default.homeDirectoryForCurrentUser
    .appending(path: "Documents/QiskitFigures", directoryHint: .isDirectory)
var format = "both"
var selectors: [String] = []
var listOnly = false

var arguments = CommandLine.arguments.dropFirst()
while let argument = arguments.popFirst() {
    switch argument {
    case "--list":
        listOnly = true
    case "--out":
        guard let path = arguments.popFirst() else { fail("--out needs a folder") }
        folder = URL(fileURLWithPath: path, isDirectory: true)
    case "--format":
        guard let value = arguments.popFirst(), ["png", "pdf", "both"].contains(value) else {
            fail("--format must be png, pdf or both")
        }
        format = value
    default:
        selectors.append(argument)
    }
}

MainActor.assumeIsolated {
    let all = Figures.all

    if listOnly {
        for figure in all { print("\(figure.group)\t\(figure.name)") }
        return
    }

    let selected: [Figure]
    if selectors.isEmpty {
        selected = all
    } else {
        var chosen: [Figure] = []
        for selector in selectors {
            let matches = all.filter { $0.name == selector || $0.group == selector }
            if matches.isEmpty { fail("No figure or group called \(selector). Use --list.") }
            chosen += matches.filter { match in !chosen.contains { $0.name == match.name } }
        }
        selected = chosen
    }

    do {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for figure in selected {
            if format != "pdf" { try figure.view.writePNG(to: folder.appending(path: "\(figure.name).png")) }
            if format != "png" { try figure.view.writePDF(to: folder.appending(path: "\(figure.name).pdf")) }
        }
        print("Wrote \(selected.count) figure(s) to \(folder.standardizedFileURL.path)")
    } catch {
        fail("Export failed: \(error)")
    }
}
