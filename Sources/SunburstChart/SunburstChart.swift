import SwiftUI

/// A tree as rings around its root: the bigger an item, the wider its piece. Hovering names the
/// piece in the middle; a click or tap hands it to `onSelect`. Every piece is a button for
/// VoiceOver, with its label and detail.
public struct SunburstChart<Item: Identifiable>: View {
    private let root: Item
    private let children: (Item) -> [Item]
    private let value: (Item) -> Double
    private let label: (Item) -> String
    private let detail: (Item) -> String
    private let onSelect: (Item) -> Void
    private let layout: SunburstLayout<Item>
    private let colors: [Color]
    private let revision: Int
    @State private var hovered: Item?
    /// Laid out when the chart is made and again when its root or revision changes, never on a
    /// mouse move.
    @State private var segments: [SunburstSegment<Item>]

    /// Outer rings fade, so the inner ones read first.
    private static var ringOpacities: [Double] { [1.0, 0.75, 0.5] }
    private static var gapShare: Double { 0.004 }
    private static var nameLines: Int { 2 }
    private static var half: Double { 0.5 }
    private static var quarterTurn: Double { 0.25 }
    private static var circleDegrees: Double { 360 }

    /// The colors of the branches, one per child of the root, repeating when there are more.
    public static var defaultColors: [Color] {
        [.blue, .teal, .green, .orange, .pink, .purple, .indigo, .mint, .red, .yellow]
    }

    /// - Parameters:
    ///   - root: the item in the middle; its children form the first ring.
    ///   - children: the children of an item, in the order they go around the circle.
    ///   - value: the size of an item, such as its bytes; a parent's value covers its children.
    ///   - label: what the middle and VoiceOver call an item.
    ///   - detail: a second line, such as a formatted size.
    ///   - rings: how many rings are drawn around the root.
    ///   - colors: one color per branch; outer rings show it fainter.
    ///   - revision: change it when the tree's contents change but the root stays the same.
    ///   - onSelect: what a click, a tap or VoiceOver's action on a piece does.
    public init(
        root: Item, children: @escaping (Item) -> [Item], value: @escaping (Item) -> Double,
        label: @escaping (Item) -> String, detail: @escaping (Item) -> String = { _ in "" },
        rings: Int = 3, colors: [Color] = defaultColors, revision: Int = 0,
        onSelect: @escaping (Item) -> Void = { _ in }
    ) {
        self.root = root
        self.children = children
        self.value = value
        self.label = label
        self.detail = detail
        self.layout = SunburstLayout(rings: rings)
        self.colors = colors.isEmpty ? Self.defaultColors : colors
        self.revision = revision
        self.onSelect = onSelect
        // ponytail: laid out on every init, though @State keeps only the first value; the layout
        // stops at the rings and at thin pieces, so it stays small. Cache by LayoutKey if a big
        // tree and a busy parent make it show up in a profile.
        _segments = State(initialValue: layout.segments(of: root, children: children, value: value))
    }

    public var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            ZStack {
                ForEach(segments, content: piece)
                centerLabel.frame(width: diameter * layout.holeShare)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(.rect)
            // One hit test for all pieces: a shape's own hover area would be its whole frame.
            .onContinuousHover { phase in
                hovered = hoveredItem(phase, in: geometry.size)
            }
            .gesture(
                SpatialTapGesture().onEnded { tap in select(at: tap.location, in: geometry.size) })
        }
        .task(id: LayoutKey(root: root.id, revision: revision)) {
            segments = layout.segments(of: root, children: children, value: value)
            hovered = nil  // it belonged to the tree before
        }
    }

    private func piece(_ segment: SunburstSegment<Item>) -> some View {
        let inner = layout.innerRadius(ofRing: segment.ring)
        let opacities = Self.ringOpacities
        return RingPiece(
            start: segment.start, end: segment.end, inner: inner,
            outer: inner + layout.ringWidth, gap: Self.gapShare
        )
        .fill(colors[segment.branch % colors.count])
        .opacity(opacities[min(segment.ring, opacities.count - 1)])
        .accessibilityElement()
        .accessibilityLabel(label(segment.item))
        .accessibilityValue(detail(segment.item))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onSelect(segment.item) }
    }

    private func select(at point: CGPoint, in size: CGSize) {
        if let found = segment(at: point, in: size) {
            onSelect(found.item)
        }
    }

    private func hoveredItem(_ phase: HoverPhase, in size: CGSize) -> Item? {
        guard case .active(let location) = phase else { return nil }
        return segment(at: location, in: size)?.item
    }

    /// Turns a point into a distance and an angle from the middle and looks up the piece there.
    private func segment(at point: CGPoint, in size: CGSize) -> SunburstSegment<Item>? {
        let radius = min(size.width, size.height) * Self.half
        let offsetX = point.x - size.width * Self.half
        let offsetY = point.y - size.height * Self.half
        let fullTurn = Angle.degrees(Self.circleDegrees).radians
        let turn = (atan2(offsetY, offsetX) / fullTurn + Self.quarterTurn + 1)
            .truncatingRemainder(dividingBy: 1)
        return layout.segment(atRadius: hypot(offsetX, offsetY) / radius, turn: turn, in: segments)
    }

    private var centerLabel: some View {
        let shown = hovered ?? root
        return VStack(spacing: 2) {
            Text(label(shown)).font(.headline).lineLimit(Self.nameLines)
            Text(detail(shown)).font(.caption).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .accessibilityHidden(true)  // every piece names itself
    }
}

/// What the layout depends on, so it is computed again only when one of them changes.
private struct LayoutKey<ID: Hashable>: Hashable {
    let root: ID
    let revision: Int
}

/// A piece of a ring between two shares of the circle, starting at the top and going clockwise.
struct RingPiece: Shape {
    let start, end, inner, outer, gap: Double

    private static var circleDegrees: Double { 360 }
    private static var topDegrees: Double { -90 }
    private static var half: Double { 0.5 }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) * Self.half
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfGap = gap * Self.half
        let startAngle = angle(start + halfGap)
        let endAngle = angle(max(end - halfGap, start + halfGap))
        var path = Path()
        path.addArc(
            center: center, radius: radius * outer, startAngle: startAngle, endAngle: endAngle,
            clockwise: false)
        path.addArc(
            center: center, radius: radius * inner, startAngle: endAngle, endAngle: startAngle,
            clockwise: true)
        path.closeSubpath()
        return path
    }

    private func angle(_ share: Double) -> Angle {
        .degrees(Self.topDegrees + Self.circleDegrees * share)
    }
}
