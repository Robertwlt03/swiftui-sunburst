// swift-tools-version:6.0
// A sunburst chart for SwiftUI: a tree as rings around its root, each piece as wide as its share.
//
// Start:  add https://github.com/Robertwlt03/swiftui-sunburst as a package dependency, then
//         import SunburstChart; swift test runs the tests
// Needs:  Swift 6, macOS 14 or iOS 17
import PackageDescription

let package = Package(
    name: "SunburstChart",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "SunburstChart", targets: ["SunburstChart"])
    ],
    targets: [
        .target(name: "SunburstChart"),
        .testTarget(name: "SunburstChartTests", dependencies: ["SunburstChart"]),
    ]
)
