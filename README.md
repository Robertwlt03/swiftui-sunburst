<p align="center">
  <img src="assets/banner-readme.svg" alt="swiftui-sunburst: a tree as rings, for SwiftUI on macOS and iOS." width="100%">
</p>

A sunburst chart for SwiftUI: a tree as rings around its root, each piece as wide as its share of its parent. Hover
names the piece in the middle, a click or tap selects it, and VoiceOver reads every piece as a button.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/preview-dark.png">
    <img src="assets/preview-light.png" alt="A sunburst of a home folder: Library, Pictures, Developer, Movies and Documents as the first ring, their subfolders fainter outside." width="420">
  </picture>
</p>

## <img src="assets/icons/features.svg" height="33" align="absmiddle" alt="">What it does

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/pictures/features-dark.svg">
  <img src="assets/pictures/features-light.svg" alt="Any tree: folders, budgets, categories, anything with children and a value. Hover and click: the middle names the piece under the pointer; a click or tap selects it. VoiceOver: every piece is a button with its label and detail. Light and dark: system colors per branch, outer rings fainter, on macOS and iOS. Laid out once: the rings are computed when the tree changes, never on a mouse move. No dependencies: SwiftUI only, Swift 6 with strict concurrency." width="100%">
</picture>

## <img src="assets/icons/install.svg" height="33" align="absmiddle" alt="">Install

Swift 6, macOS 14 or iOS 17. In `Package.swift`, then add the product `SunburstChart` to your target:

```swift
dependencies: [.package(url: "https://github.com/Robertwlt03/swiftui-sunburst", from: "0.1.0")]
```

## <img src="assets/icons/use.svg" height="33" align="absmiddle" alt="">Use

Any `Identifiable` type works; say how to reach its children, its value and its name:

```swift
import SunburstChart
import SwiftUI

struct Folder: Identifiable {
    let id: String
    let size: Double
    var children: [Folder] = []
}

struct FolderChart: View {
    let home: Folder
    @State private var opened: Folder?

    var body: some View {
        SunburstChart(
            root: home, children: \.children, value: \.size, label: \.id,
            detail: { folder in "\(Int(folder.size)) GB" },
            onSelect: { folder in opened = folder })
            .padding()
    }
}
```

A parent's value covers its children; what they leave free stays a gap, so the gaps show what lies in the parent
itself. Pieces thinner than 0.4 % of the circle are left out with their children, because nobody could see or click
them.

## <img src="assets/icons/options.svg" height="33" align="absmiddle" alt="">Options

| Parameter | Default | What it does |
|---|---|---|
| `detail` | empty | a second line in the middle and VoiceOver's value, such as a formatted size |
| `rings` | `3` | how many rings are drawn around the root |
| `colors` | system colors | one color per branch (child of the root), repeating when there are more |
| `revision` | `0` | change it when the tree's contents change but the root's identity stays |
| `onSelect` | nothing | what a click, a tap or VoiceOver's action on a piece does |

`SunburstLayout` computes the rings without drawing them, for a chart of your own or for tests.

## <img src="assets/icons/contribute.svg" height="33" align="absmiddle" alt="">Contribute

Issues and pull requests are welcome. The tests check the layout; the README's pictures are drawn by a test too:

```bash
swift test
```

```bash
SUNBURST_PREVIEW=$PWD/assets/preview swift test --filter drawPreview
```

## <img src="assets/icons/license.svg" height="33" align="absmiddle" alt="">License

[MIT](LICENSE)
