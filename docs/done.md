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
