# CLAUDE.md

Guidance for Claude Code working in this repository.

## What this is

Padiddle is an iOS app that draws pictures as you spin your device on your finger. Device motion
(Core Motion) drives a nib that paints into an offscreen `CGContext`.

Separately from the spinning, a counter-rotating view cancels out **interface orientation** changes:
the UI rotates as you move between portrait and landscape, but the drawing holds its orientation
relative to the hardware. Same behavior as the Procreate canvas on iPad. This has nothing to do with
the continuous spin — it only reacts when the interface orientation changes.

See `Readme.md` for the project layout and first-time setup.

## Build and test

**Use the Xcode MCP server (`xcode`, backed by `xcrun mcpbridge`) for every build, test, and
simulator run.**

Do **not** shell out to `xcodebuild`, `swift build`, `swift test`, or `xcrun simctl` — not as a
fallback, not "just to check something quickly," not when the MCP call errors. If the MCP server is
not connected, **stop and ask for it to be reconnected**, and wait. Working around it with the
command line is only acceptable when explicitly instructed in that moment.

Facts to drive the MCP with:

- **Project:** `Padiddle.xcodeproj` (no workspace).
- **App scheme:** `Padiddle`. Screenshot schemes: `Screenshots`, `ScreenshotsForWebsite`.
- **Test plans:** `Padiddle` (all three test targets — PadiddleCoreTests, ModelsTests,
  UtilitiesTests), `PadiddleCore` (logic tests only), `SnapshotTestHost` (ModelsTests on the
  snapshot host app).
- **Destination:** an iOS Simulator. The package declares `.iOS(.v26)` only, so there is no macOS
  or "My Mac" path — a simulator destination is always required.
- The SwiftPackageList build plugin needs package plugin validation skipped; the fastlane lanes
  already pass `-skipPackagePluginValidation`.

`bundle exec fastlane test` exists and is fine when the task is specifically about the fastlane
lanes. Ruby tooling is managed with `mise` — see the comment at the top of `Gemfile`.

## Lint and format

```sh
Scripts/lint.sh              # SwiftFormat (auto-fixes) + SwiftLint --strict
Scripts/_lint.sh update      # bump the pinned tool versions to latest
```

These are plain shell scripts, not build/test commands — running them directly is correct.

SwiftFormat and SwiftLint are pinned by `Scripts/swiftformat-version` / `Scripts/swiftlint-version`
and auto-downloaded into `Scripts/.bin/` (gitignored). Always go through `Scripts/lint.sh` rather
than invoking `Scripts/.bin/swiftformat` directly — the script reinstalls the binary when the cached
one doesn't match the pinned version, and a stale binary will reject rules the config uses. The
pre-commit hook runs the same script, so a commit fails if SwiftFormat rewrote anything — review and
re-stage.

Style highlights from `.swiftformat` / `.editorconfig`: **2-space indent**, wrap arguments,
parameters and collections *before first*, trailing commas in collections only, `self` only in
`init`, imports sorted with `@testable` last, no file headers.

## Conventions

**TCA.** This project is on **TCA 2.0** — the `TCA26` package pinned to `branch: "main"`, importing
the `ComposableArchitecture1` compatibility module (a 1.x-shaped surface on the 2.0 runtime). TCA 2.0
is a beta with no published migration guide; `docs/done.md` records what the port established, and
the [beta preview post](https://www.pointfree.co/blog/posts/206-beta-preview-composablearchitecture-2-0)
is the closest thing to an outline.

Each feature is a `@Feature` struct paired with its SwiftUI view **in the same file**, named after
the view: `RootView.swift` holds `RootFeature` + `RootView`, `ToolbarView.swift` holds
`ToolbarFeature` + `ToolbarView`. Reducer-only features (`HintFeature`, `DeviceMotionFeature`) get
their own file.

Within a feature:
- The body is `var body: some FeatureProtocol<State, Action>`, assembled from `Scope`s, one or more
  `Update { state, action in … }` blocks, and modifiers (`.onMount`, `.onChange(of:)`,
  `.onTrigger(_:)`, `.ifLet`). `Update` returns nothing — async work goes through
  `store.addTask { … }`.
- Child-to-parent communication is a **delegate closure** passed to the child's init
  (`DeviceMotionFeature(delegate: { action in … })`), not a nested `case delegate(Delegate)` action.
  The child declares `enum DelegateAction` and holds `let delegate: (DelegateAction) throws -> Void`.
- Parent-to-child commands are `@Trigger` properties on the child's state (`@Trigger var start`),
  fired from the parent as `try store.toolbar.hint.start()` and handled with `.onTrigger(store.start)`.
- Cancellation tokens are `@StoreTaskID` properties on the feature, not a nested `enum CancelID`.
- **Cancels must be deferred.** Calling `someID.cancel()` straight from a feature body traps with
  "Can't cancel a store task synchronously from a feature body." Always wrap it:
  `store.addTask { someID.cancel() }`.
- **`addTask(id:)` accumulates.** There is no implicit cancel-in-flight. To restart a task, cancel
  immediately before starting: `store.addTask { id.cancel() }` then `store.addTask(id: id) { … }`.
- **`.onMount` is feature-lifetime scoped**, not view-visibility scoped the way 1.x `.task`/`onTask`
  was. It does *not* fire again when a sheet or popover presented over the feature is dismissed —
  `ToolbarView` compensates with `.onChange(of: store.destination)`. On a test core the hooks are
  also not run immediately at construction, which is why mount-time state changes are asserted
  through `TestStore`'s `changes:` closure — see **Tests** below.
- Navigation is a plain `var destination: Destination.State?` plus a `@Feature enum Destination`,
  attached with `.ifLet(\.destination, action: \.destination) { Destination.body }`.
- Timing/layout constants live in a nested `enum Design`.

**Dependencies.** Live in `PadiddleCore/Dependencies/`, declared with `@DependencyClient` and
registered via a `DependencyValues` extension in the same file. Clients that must not ship a live
implementation in the package (e.g. `ImageIO`) conform to `TestDependencyKey` only; the app target
supplies `liveValue` in `PadiddleApp.swift`.

**Shared state.** `@Shared`/`@SharedReader` keys are declared at the top of `ToolbarView.swift`:
`.isRecording` (in-memory) and `.colorGenerator` (app storage). Mutate through
`$value.withLock { … }`.

**Localization.** String catalogs at `Sources/*/Resources/Localizable.xcstrings`, referenced through
generated symbols (`String(localized: .erase)`), plus per-language `about.html` under
`PadiddleCore/Resources/<lang>.lproj/`. Supported: en (base), fr, it, nl, zh-Hans, zh-Hant. Resource
lookup uses the `#bundle` macro, not `Bundle.module`.

**Tests.** Swift Testing (`@Suite` / `@Test`), not XCTest. Feature tests use TCA's `TestStore` with
dependencies overridden in the `withDependencies:` trailing closure. Image snapshots live in
`__Snapshots__/` and are LFS-tracked; the suite records with `.snapshots(record: .failed)`.

A feature that mutates state in `.onMount` must be constructed with the `changes:` overload, which
asserts the mount-time mutation — a `store.expect { }` placed after construction reports "no changes
occurred" while the construction site still flags them:

```swift
TestStore(initialState: RootFeature.State()) {
  RootFeature()
} changes: {
  $0.toolbar.hint.hintState = .waitToShowRecordPrompt
}
```

End such a test with `await store.dismount()` to tear down lifetime-scoped tasks (e.g. the
`Observations` loop in `HintFeature`).

**UIKit interop.** Several SwiftUI views wrap UIKit for things SwiftUI can't do: `ScreenReader`
(screen size/scale via `didMoveToWindow`), `CounterRotatingView` (counter-rotates the content against
`windowScene.effectiveGeometry.interfaceOrientation` so the drawing stays fixed to the hardware),
`LayerHostingView` (hosts the persistent drawing `CALayer`).

## Debugging

In DEBUG builds, double-tapping the drawing area sends `.debugDrawImage`, which replays recorded
motion from `PadiddleCore/Resources/sample_drawing.json` to produce a deterministic drawing. The
root store emits `OSSignposter` events for every action from `RootFeature`'s first `Update`, and is
wired with `RootFeature._logChanges()`. A commented-out `_printChanges` printer that filtered the
noisy per-frame motion actions is still in `RootView.swift`, alongside a `#warning` about redoing
that filtering the TCA 2 way.

## Planned work

`docs/todo.md` holds open work and open questions; `docs/done.md` records finished work worth
remembering (mostly TCA 2 migration findings). Check `docs/todo.md` before starting something that
looks unfinished — it may be deliberate.

## Screenshots

```sh
bundle exec fastlane screenshots            # App Store, 4 devices × 6 languages
bundle exec fastlane screenshotsForWebsite  # framed marketing shots
```

Screenshot runs set `FASTLANE_SNAPSHOT=YES`; a build phase then copies
`Screenshots/ScreenshotPersistedImage-*.png` into the app bundle and `DrawingFeature` loads the
matching one instead of drawing live, so screenshots are reproducible.
