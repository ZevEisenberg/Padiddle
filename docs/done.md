# Done

Finished work worth remembering — mostly findings from the TCA 2 port that aren't recoverable from
the diff. Open items live in [todo.md](todo.md).

## TCA 2 port (branch `tca2`)

Ported the app from TCA 1.x to TCA 2.0 (the `TCA26` package). The mechanical parts are visible in
the diff; these are the things that cost time to work out.

### Dependency graph

`xctest-dynamic-overlay` and `swift-issue-reporting` are **separate repos with separate HEADs** that
both vend an `IssueReporting` module. Mixing them produces
`Compilation search paths unable to resolve module dependency: 'IssueReportingPackageSupport'`,
because that module exists only in the old repo. Fixed by moving everything onto
`swift-issue-reporting` and updating `TCA26` to a `main` that had already dropped the old one.

Xcode will not re-resolve on its own after this kind of change — builds no-op in under a second and
`workspace-state.json` stays untouched. File ▸ Packages ▸ Update to Latest Package Versions is what
actually shakes it loose, and reopening the project clears the stale in-memory package graph that
produces phantom errors about files and products that no longer exist.

### Store tasks

- `someID.cancel()` traps if called synchronously from a feature body
  (`Can't cancel a store task synchronously from a feature body`). It must be deferred into
  `store.addTask { someID.cancel() }`. This diagnostic predates the version bump — it is not a
  regression from updating packages.
- `store.addTask(id:)` **accumulates** tasks under that id; there is no implicit cancel-in-flight.
  `cancel()` cancels every task attached to the id. To emulate 1.x's `cancelInFlight: true`, cancel
  in a deferred task immediately before starting the new one.

### `onMount` is not `onTask`

`main`'s `ToolbarView` started the hint flow from `.task { await store.send(.onTask).finish() }`,
which is scoped to **view visibility**. The port uses `.onMount`, which is scoped to **feature
lifetime**. TCA 2's lifecycle docs are explicit: "If another feature is presented on top of a
feature that uses `onMount`, the `onMount` is not invoked again when the new feature is dismissed."

Two consequences, both handled:

- The hint prompt no longer returned after a sheet or popover was dismissed. `ToolbarView` now
  re-triggers on `.onChange(of: store.destination)` when the destination goes non-nil → nil.
- `main`'s `RootFeatureTests` never saw any hint activity, because a `TestStore` has no view and
  therefore never ran the `.task`. Under `.onMount` the hint flow runs in tests, so both tests had
  to be rewritten around it.

While here, added a genuinely new behavior: foregrounding the app also re-triggers the hint
(`RootView`, `scenePhase == .active`). See [todo.md](todo.md) for the case it still doesn't cover.

### `isPresented` does not mean what the old guard assumed

`DeviceMotionFeature` carried `guard store.isPresented else { return }` at the top of `.start`. In
TCA 2, `_Core.isPresented` is `eventHandlers.hasHandler(for: DismissEventKey.self)` — it is the
equivalent of SwiftUI's `@Environment(\.isPresented)`, answering "am I presented by someone?", not
"is something covering me?". A root feature is never presented, so the guard was permanently false
and would have stopped motion updates in the shipping app, not just in tests. Removed.

`Tests/PadiddleCoreTests/Helpers/TestWrapper.swift` was built on the same misreading — its doc
comment claimed features "will only report `isPresented == true` if they are wrapped in another
feature," but a plain `Scope` installs no `DismissEventKey` handler, so wrapping changed nothing.
Deleted, and its two users converted to plain `TestStore(initialState:)`.

### Testing mount-time state

A feature that mutates state in `.onMount` needs the `TestStore(initialState:feature:changes:)`
overload — its closure is documented as "responsible for asserting against any initial mutations
made by the feature at mount time." Nothing else works: mount changes are attributed to the
construction site, so a `store.expect { }` after construction reports "State changes expected, but
none occurred" while the construction line separately flags the unasserted change.

This isn't in the docs — `TestingFeatures.md` is an empty stub, and TCA 2's own `OnMountTests` only
ever start tasks in `onMount`, never mutate state, so there's no example of it anywhere.

Tests that rely on lifetime-scoped tasks should end with `await store.dismount()`.

### The root store must be `@State`

`main` held the root store as a plain stored property — `let store = StoreOf<RootFeature>(...)` — on
`RootView`, and that survived 1.x fine. Under TCA 2 it makes the app loop forever on launch:
`RootView.init` ran ~60×/second, and because the store is a stored-property initializer, every one
of those inits built a **brand-new root store with fresh `.init()` state**. The evidence in the log
was a `RootFeature.toolbar: mount` / `dismount` pair every frame, where each dismount snapshot read
`hintState: .waitToShowRecordPrompt` (written by `.onMount`) and the very next mount snapshot read
`hintState: .initial` — state that has no business resetting unless the whole store is new.

It is self-feeding: the new store's `.onMount` writes state, that invalidates the view, SwiftUI
rebuilds `RootView`, which builds another store. Fix is `@State private var store = ...`, which is
what every store in TCA 2's own `Examples/` uses.

### Where to actually learn this

TCA 2 has no published documentation. In descending order of usefulness:
`Documentation.docc/Articles/FeatureFundamentals/FeatureFundamentals-Lifecycle.md` (solid),
`-StoreTaskManagement.md` (several sections still say "TODO: todo"), the repo's own test suite, and
the pull requests — #204 (which gated hooks off on test cores), #202, #186, #185.

## iPhone Duo book mode: toolbar on its own page

On a folded Duo, the toolbar moves onto the right-hand page while the drawing runs unbroken across
the whole inner display. This is `ArrangementView` (iOS 27.1) doing the work; the code that opts in
is a few lines in `RootView.arrangedContent`. These are the things that cost time to work out.

### The fold APIs are in SwiftUICore, not SwiftUI

`ArrangementView`, `OverlayArrangementViewStyle`, `ReservedRegion` and `DeviceHinge` all live in
**SwiftUICore**. Grepping `SwiftUI.framework`'s swiftinterface finds none of them and produces a
confident, wrong conclusion that the whole area is UIKit-only. It isn't: no `UIHostingController`
restructuring is needed.

The one genuine gap is `UITraitCollection.verticalBarEdge`, which has no SwiftUI equivalent and
needs a `UITraitBridgedEnvironmentKey` to cross over. Its `write(to:)` is a no-op, since the trait
is read-only. The protocol requirement is `inout any UIMutableTraits` — `some` does not satisfy it.

`DeviceHinge` has **no** environment key, only `View.onHingeChange(_:)`. The pose is available more
cheaply as `isActive` on `reservedRegions(kind: .division)`, which is what the spike measured with.

### In an overlay arrangement, the primary is the foreground

Not the other way round. With the canvas as primary the toolbar is invisible *and* untappable,
because the opaque canvas covers it and swallows its touches. Two independent confirmations: the
Tech Talk swaps primary and secondary when moving from `.split` to `.overlay`, and
`@Environment(\.overlayArrangementZIndex)` reports 1 for primary against 0 for secondary.

The same environment value doubles as a pose readout: `1 / 0` means the children are stacked, and
`0 / 0` means the system has split them one per page.

### The canvas can't be an arrangement child

An arrangement sizes and positions each child **within a single page**. The drawing takes its
square from whatever box it is laid out in, so as the secondary it came out one page wide and
centered on that page — 669pt at x 228 instead of 951pt centered on the display. The visible symptom
was a debug drawing that appeared only on the left page and a double-tap that only worked there.

It is not clipping. The arrangement does not forbid its children from crossing the fold; the
drawing simply never reached that far. So the canvas hangs off `.background` on the
`ArrangementView`, spanning the whole display, and the secondary is a `Color.clear` placeholder
whose only job is to occupy the page the toolbar vacated. An empty secondary is enough — the
arrangement still displaces the toolbar.

For the same reason `DrawingFeature.viewSize` no longer comes from `DrawingView`'s own
`GeometryProxy`. It is set from `ScreenMetrics` in `RootFeature`, which stays whole in every pose.

### Duo geometry, measured

| pose | window | each region | zIndex | division |
|---|---|---|---|---|
| inner, flat | 951×669 | 951×635, stacked | 1 / 0 | `off` x456 w40 |
| inner, book | 951×669 | 456×635, one per page | 0 / 0 | **`on`** x456 w40 |
| cover | 466×678 | 382×644, stacked | 1 / 0 | none; 2 active occlusions |

The fold is 40pt at x 456–496. `GeometryProxy.size` excludes safe-area insets while
`reservedRegions` frames do not, which is why the region heights are 34pt short of the window.

### `verticalBarEdge` is not a pose signal

It reports `.trailing` in **all three** poses, including the closed cover display in portrait. It
never returns `.unspecified` and never flips to `.leading`. So it answers "which side, if you show
one," not "should you show one" — the decision to go vertical would have been entirely ours.

This is what ruled out the alternative design (a bar that moves to the leading/trailing edge
depending on pose). Measured on one beta simulator; the header documents `.unspecified` for
contexts where no vertical bar is used, so this may just be unimplemented in the beta.

### A cutout insets the whole height

`safeAreaInsets` applies a display cutout's full width down the entire scene, not just the rows it
occupies. On the cover display that is an 84pt trailing inset for a camera whose occlusion region
is `382,0 84x82` — the top corner only — and it pushed the bottom bar 42pt off center. The toolbar
takes `.ignoresSafeArea(.container, edges: .horizontal)`, which is safe only because the bar is
narrow and centered and so never reaches a cutout at either end.
