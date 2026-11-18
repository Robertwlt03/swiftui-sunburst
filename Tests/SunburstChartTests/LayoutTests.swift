import SwiftUI
import Testing

@testable import SunburstChart

/// A folder with a size; its own files take what its children leave.
struct Folder: Identifiable {
    let id: String
    let size: Double
    var children: [Folder] = []
}

private let tree = Folder(
    id: "root", size: 100,
    children: [
        Folder(id: "a", size: 50, children: [Folder(id: "a1", size: 25)]),
        Folder(id: "b", size: 30),
        Folder(id: "tiny", size: 0.1),
    ])

private func segments(rings: Int = 3) -> [SunburstSegment<Folder>] {
    SunburstLayout<Folder>(rings: rings).segments(of: tree, children: \.children, value: \.size)
}

@Test("Each child takes its share of its parent's piece")
func childrenTakeTheirShare() throws {
    let byName = Dictionary(uniqueKeysWithValues: segments().map { ($0.item.id, $0) })
    let first = try #require(byName["a"])
    let second = try #require(byName["b"])
    let inner = try #require(byName["a1"])
    #expect((first.start, first.end, first.ring) == (0, 0.5, 0))
    #expect((second.start, second.end) == (0.5, 0.8))
    #expect((inner.start, inner.end, inner.ring) == (0, 0.25, 1))
}

@Test("A branch keeps the color of the root's child it lies in")
func branchesKeepTheirColor() throws {
    let inner = try #require(segments().first { segment in segment.item.id == "a1" })
    #expect(inner.branch == 0)
}

@Test("Pieces too thin to see are left out, and so are rings beyond the limit")
func thinPiecesAndOuterRingsAreLeftOut() {
    #expect(!segments().contains { segment in segment.item.id == "tiny" })
    #expect(!segments(rings: 1).contains { segment in segment.ring > 0 })
}

@Test("A point finds the piece under it, and nothing in the hole or outside")
func pointsFindTheirPiece() {
    let layout = SunburstLayout<Folder>()
    let all = segments()
    let firstRing = layout.innerRadius(ofRing: 0) + layout.ringWidth / 2
    #expect(layout.segment(atRadius: firstRing, turn: 0.6, in: all)?.item.id == "b")
    #expect(layout.segment(atRadius: 0.1, turn: 0.6, in: all) == nil)
    #expect(layout.segment(atRadius: 1.2, turn: 0.6, in: all) == nil)
}

@Test("Settings outside their sense are moved to ones that work")
func settingsAreKeptSensible() {
    let layout = SunburstLayout<Folder>(rings: 0, holeShare: 1.5, smallestShare: -1)
    #expect((layout.rings, layout.holeShare, layout.smallestShare) == (1, 0.9, 0))
    #expect(layout.ringWidth > 0)
}

@Test("A child whose value is no number takes no room from its siblings")
func brokenValuesTakeNoRoom() throws {
    let root = Folder(
        id: "root", size: 10,
        children: [Folder(id: "broken", size: .nan), Folder(id: "fine", size: 5)])
    let found = SunburstLayout<Folder>().segments(of: root, children: \.children, value: \.size)
    let fine = try #require(found.first { segment in segment.item.id == "fine" })
    #expect((fine.start, fine.end) == (0, 0.5))
}

@Test("An empty or weightless root draws no pieces")
func emptyRootDrawsNothing() {
    let empty = Folder(id: "empty", size: 0, children: [Folder(id: "x", size: 0)])
    let layout = SunburstLayout<Folder>()
    #expect(layout.segments(of: empty, children: \.children, value: \.size).isEmpty)
}

/// A home folder for the README's picture.
private let home = Folder(
    id: "Home", size: 420,
    children: [
        Folder(
            id: "Library", size: 160,
            children: [
                Folder(id: "Caches", size: 70, children: [Folder(id: "Browser", size: 40)]),
                Folder(id: "Containers", size: 55), Folder(id: "Mail", size: 20),
            ]),
        Folder(
            id: "Pictures", size: 110,
            children: [
                Folder(id: "Photos", size: 95, children: [Folder(id: "Originals", size: 80)])
            ]
        ),
        Folder(
            id: "Developer", size: 80,
            children: [Folder(id: "Xcode", size: 50), Folder(id: "Projects", size: 25)]),
        Folder(id: "Movies", size: 40, children: [Folder(id: "Exports", size: 30)]),
        Folder(id: "Documents", size: 20),
    ])

/// Draws the chart light and dark into SUNBURST_PREVIEW-light.png and -dark.png, for the README.
@MainActor
@Test(
    "The chart draws",
    .enabled(if: ProcessInfo.processInfo.environment["SUNBURST_PREVIEW"] != nil))
func drawPreview() throws {
    let base = try #require(ProcessInfo.processInfo.environment["SUNBURST_PREVIEW"])
    for scheme in [ColorScheme.light, .dark] {
        let chart = SunburstChart(
            root: home, children: \.children, value: \.size, label: \.id,
            detail: { folder in "\(Int(folder.size)) GB" }
        )
        .frame(width: 600, height: 600)
        .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: chart)
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        let url = URL(fileURLWithPath: "\(base)-\(scheme == .light ? "light" : "dark").png")
        let destination = try #require(
            CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
    }
}
