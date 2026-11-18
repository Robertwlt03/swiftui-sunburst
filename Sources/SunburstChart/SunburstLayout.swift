import Foundation

/// One item as a piece of a ring: its ring counted from the inside, and where it starts and ends
/// as a share of the full circle, clockwise from the top.
public struct SunburstSegment<Item: Identifiable>: Identifiable {
    public let item: Item
    public let ring: Int
    public let start: Double
    public let end: Double
    /// The child of the root it lies in, so a branch keeps one color outwards.
    public let branch: Int
    public var id: Item.ID { item.id }
}

/// Lays out a tree as rings: each item takes the share of its parent's piece that its value takes
/// of the parent's value. What the children do not cover stays a gap, so the gaps show what lies
/// in the parent itself.
public struct SunburstLayout<Item: Identifiable> {
    public let rings: Int
    /// The empty middle, as a share of the radius; the rings share the rest equally.
    public let holeShare: Double
    /// Thinner pieces could not be seen or clicked, so they are left out with their children.
    public let smallestShare: Double

    /// Values outside their sense are moved to the nearest one that works: at least one ring, a
    /// hole of up to 90 % of the radius, and no negative share.
    public init(rings: Int = 3, holeShare: Double = 0.3, smallestShare: Double = 0.004) {
        self.rings = max(rings, 1)
        self.holeShare = min(max(holeShare, 0), 0.9)
        self.smallestShare = max(smallestShare, 0)
    }

    public var ringWidth: Double { (1 - holeShare) / Double(rings) }

    public func innerRadius(ofRing ring: Int) -> Double { holeShare + ringWidth * Double(ring) }

    /// The pieces of the root's children and their children, up to the number of rings.
    public func segments(
        of root: Item, children: @escaping (Item) -> [Item], value: @escaping (Item) -> Double
    ) -> [SunburstSegment<Item>] {
        var walk = Walk(layout: self, children: children, value: value)
        walk.addChildren(of: root, within: 0...1, ring: 0, branch: nil)
        return walk.segments
    }

    /// One pass over the tree: how to read it, and the pieces found so far.
    private struct Walk {
        let layout: SunburstLayout
        let children: (Item) -> [Item]
        let value: (Item) -> Double
        var segments: [SunburstSegment<Item>] = []

        mutating func addChildren(
            of parent: Item, within span: ClosedRange<Double>, ring: Int, branch: Int?
        ) {
            let total = value(parent)
            guard layout.rings > ring, total > 0, total.isFinite else { return }
            let sharePerUnit = (span.upperBound - span.lowerBound) / total
            var start = span.lowerBound
            for (index, child) in children(parent).enumerated() {
                // A value that is no number (NaN, infinite) or negative counts as nothing, so it
                // cannot shift its siblings.
                let size = value(child)
                let end = start + (size.isFinite ? max(size, 0) : 0) * sharePerUnit
                if end - start >= layout.smallestShare {
                    let childBranch = branch ?? index
                    segments.append(
                        SunburstSegment(
                            item: child, ring: ring, start: start, end: end, branch: childBranch))
                    addChildren(of: child, within: start...end, ring: ring + 1, branch: childBranch)
                }
                start = end
            }
        }
    }

    /// The piece at a point given by its distance from the middle (a share of the radius) and its
    /// angle (a share of the full turn, clockwise from the top).
    public func segment(
        atRadius radius: Double, turn: Double, in segments: [SunburstSegment<Item>]
    ) -> SunburstSegment<Item>? {
        guard radius >= holeShare, radius < 1 else { return nil }
        let ring = Int((radius - holeShare) / ringWidth)
        return segments.first { segment in
            segment.ring == ring && segment.start <= turn && turn < segment.end
        }
    }
}
