# Plan: resize the canvas across displays without erasing it

Fixes the todo item "Folding between displays won't resize the drawing — and fixing it naively
erases it" (`docs/todo.md`), plus an off-center stroke bug found while investigating it.

**Each step is meant to be done in a fresh context.** Read this whole file first, then do the
first unchecked step only. When it's finished, tick its box, add anything the next step needs to
know under its **Notes**, and stop. Follow `CLAUDE.md`: builds, tests and simulator runs go through
the Xcode MCP server, and Duo work uses the "Duo Padiddle" simulator. Don't run `Scripts/lint.sh`
by hand; the pre-commit hook runs it.

## Background (established during investigation)

- `ScreenReader` (`Packages/Sources/PadiddleCore/Drawing/ScreenReader.swift`) reports
  `ScreenMetrics` (screen size in points + scale) only from `didMoveToWindow`, so only once.
- `RootFeature`'s `.screenChanged` (`RootView.swift`, second `Update`) sets
  `drawing.contextSideLength = max(w, h)`, sets `drawing.viewSize = metrics.size`, calls
  `bitmapContext.configure(...)`, then sends `.deviceMotion(.start)`. A second `.start` is safe
  (see `DeviceMotionTests.secondStartDoesNotKillTheMonitoringLoop`).
- `BitmapContextClient.configure` (`Drawing/BitmapContextClient.swift`) allocates a **new**
  `CGContext` and drops the old one, which erases the drawing. So making `ScreenReader` reactive on
  its own would wipe the artwork on every fold/unfold.
- The canvas is a **square** of side `max(proxy.size)` (`RootView.canvas` →
  `.counterRotating(longestSideLength:)`), centered on the screen and overflowing it. The drawing
  `CALayer` is sized to that square by `LayerHostingView.layoutSubviews`, so the bitmap is
  stretched to fill whatever size the square is.
- Nib points are already in square/context coordinates: the center is `contextSideLength / 2`
  (`DrawingFeature`, `.processMotion`).
- `RootFeature.State.screenMetrics` exists but nothing sets it.
- `BitmapContextClient.testValue` is its `liveValue`, so tests can use the real context and read it
  back with `await bitmapContext.contextSideLength` / `contextOperation { … }`.
- Duo displays: inner 951×669, cover 466×678 (points).

## Steps

### [x] 1. Fix off-center strokes

**Bug:** commit eff6f02 switched `drawing.viewSize` from `DrawingView`'s own geometry, which is the
square, to `metrics.size`, the screen, which isn't square.
`DrawingFeature.State.convertViewPointToContextCoordinates` shifts each point by
`(contextSideLength - viewSize) / 2`. That was always zero with a square `viewSize`. Now it shifts
strokes off the nib: on a 390×844 phone, 227pt to the right.

**Change:** remove the conversion. `addPoint` and `restart` use the point as-is; delete
`convertViewPointToContextCoordinates` and its `fatalError`. Leave `viewSize` alone; it still
drives the spiral radius (`maxRadius`).

**Test:** add a `DrawingFeature` test (new `DrawingFeatureTests.swift` in `PadiddleCoreTests`):
state with `viewSize = 390×844`, `contextSideLength = 844`, `isRecording` shared = true, send
`.processMotion` with `rotationRateZ = 0`. Radius is 0, so expect `nibLocation` and all four
`points` to be `(422, 422)`. Before the fix, `points` would be `(649, 422)`, so confirm the test
fails before the change.

**Verify:** on the Duo Padiddle simulator, double-tap the canvas (DEBUG replay of
`sample_drawing.json`). The drawing should be centered on the screen.

**Notes:**

- Done. `addPoint(_:)` and `restart(at:)` no longer take `contextSideLength`; they store the point
  as-is. `DrawingFeatureTests.strokeStartsUnderTheNibOnANonSquareScreen` failed before the fix
  with `(649, 422)` as predicted and passes after. The full `Padiddle` test plan passes (29 tests).
- The test injects its own `BitmapContextClient` and configures it first, because `.processMotion`
  starts a task that strokes into the context, which is an implicitly unwrapped optional.
- The simulator check wasn't possible. On the Duo Padiddle simulator, the device-interaction tool
  captured only blank 678×466 screenshots while the app laid out at 951×669, and the double-taps
  had no visible effect. Check it by eye, or retry device interaction later.
- `DeviceInteractionInstallAndRun` rewrites `Padiddle.xcscheme` (debugger off, PosixSpawn
  launcher). Revert that before committing.

### [x] 2. Make the bitmap grow-only, preserving its contents

**Change `BitmapContextClient`:**

- `configure(contextSideLength:screenScale:)` becomes grow-only:
  - First call (no context yet): behave as today.
  - Later calls: if `contextSideLength <= self.contextSideLength`, do nothing and return `true`.
    Otherwise allocate the larger context, draw the old context's `makeImage()` into it
    **centered**, then swap it in.
  - Draw the old image **before** applying the flip/scale transforms, so both images are in raw
    pixel space and no y-flip is needed. The old image goes in at
    `((newPx - oldPx) / 2, (newPx - oldPx) / 2)`, size `oldPx × oldPx`.
  - Keep the **original** `screenScale` after the first configure. Mixing scales would put the old
    pixels at the wrong physical size. If the scales differ, grow the point side at the old scale.
    (Check whether the Duo's two displays even differ, and note it below.)
  - Consider renaming it to `ensureSideLength` or similar so the name doesn't suggest a reset.
- Fix the existing `bitmapBytesPerRow` math while in here: it's
  `Int(contextSideLength) * 4 * Int(screenScale)`, which is wrong for a fractional side length or
  scale. It should be `widthPx * bytesPerPixel`.

**Change `RootFeature` `.screenChanged`:**

- `state.drawing.contextSideLength = max(state.drawing.contextSideLength, maxDimension)`. It must
  always equal the bitmap's side, not the current screen's.
- `state.drawing.viewSize = metrics.size` unconditionally.
- Store `state.screenMetrics = metrics`. If `metrics` equals the previous value, return early so
  duplicate reports (step 4 will produce them) don't re-run `configure` or `.start`.

**Tests (`RootFeatureTests`, plus a `BitmapContextClient` test if cleaner):**

- A larger then a smaller `.screenChanged`: `contextSideLength` stays at the larger value, and
  `viewSize` follows the smaller one.
- Contents survive growth: configure small, fill a known pixel (e.g. the center), configure
  larger, and read back that the pixel is still set at the new center.
- The same metrics twice: the second produces no state change and no extra `.deviceMotion(.start)`.
- Existing tests assert `contextSideLength` / `viewSize` after `.screenChanged`. Update them for
  `screenMetrics` now being set.

**Notes:**

- Done. `configure(contextSideLength:screenScale:)` is now `ensureSideLength(_:screenScale:)`.
  It updates `contextSideLength` only after the new context is built, so a failed allocation
  leaves the old bitmap alone. The unused `setScreenScale(_:)` is gone, because changing the
  scale later would break the fixed-scale rule.
- The old image is placed at an integer pixel offset, `(newPx - oldPx) / 2`. With an odd
  difference, the drawing sits up to half a pixel off center, which isn't visible.
- `RootFeature` `.screenChanged` returns early for a nil or repeated `metrics`, then sets
  `screenMetrics`, `contextSideLength = max(old, w, h)` and `viewSize`.
- New tests: `BitmapContextClientTests` (contents survive growth at the new center, a smaller
  side is ignored, the first scale sticks) and `RootFeatureTests.smallerScreenKeepsTheLargerBitmap`
  / `sameScreenTwiceIsIgnored`. The `Padiddle` test plan passes (34 tests).
- Duo display scales: both the inner and cover displays are @3x, so the fixed-scale rule never
  kicks in on the Duo. The code still handles a mismatch.

### [x] 3. Size the canvas square from the bitmap, not the current screen

After step 2, the bitmap may be bigger than the current screen's square. `RootView.canvas` still
sizes the square from `max(proxy.size)`, so the layer would squash the whole bitmap into the
smaller square.

**Change:** in `RootView.canvas`, pass
`max(store.drawing.contextSideLength, max(proxy.size.width, proxy.size.height))` to
`.counterRotating(longestSideLength:)`. Before the first `.screenChanged`, `contextSideLength` is 0,
so the fallback is today's value. The square stays centered and overflows the screen, so a smaller
display shows the middle of the drawing at 1:1.

`CounterRotatingViewController` already updates its size constraints in
`updateUIViewController`, so no change is needed there. Confirm the nib overlay in `DrawingView`
still lines up, since it's positioned in square coordinates.

**Verify:** nothing observable changes yet (the reader still fires once). Run the app on the Duo
Padiddle simulator and the test plan `Padiddle` to confirm there's no regression.

**Notes:**

- Done. `RootView.canvas` passes `max(store.drawing.contextSideLength, max(proxy.size))`. The
  `Padiddle` test plan passes (34 tests), and `RunProject` on Duo Padiddle launches cleanly with no
  constraint warnings. There was no visual check (see step 1's device-interaction trouble).
- Nib overlay: `DrawingView` offsets the nib from the square's top-leading corner, and nib points
  are centered on `contextSideLength / 2`. After any `.screenChanged`, `contextSideLength >=` the
  screen's longest side, so the square's side equals `contextSideLength` and the nib stays
  centered. Before the first report, `.processMotion` bails out on a nil `viewSize`, so the two
  never disagree.
- `store.drawing.contextSideLength` is read in the view body, so SwiftUI re-renders the canvas
  when it grows. That runs `updateUIViewController`, which updates the size constraints.
- `RunProject` (unlike `DeviceInteractionInstallAndRun`) left `Padiddle.xcscheme` untouched.
- On the simulator the nib isn't centered on the inner display. That's expected: the simulator
  gives no motion data, so `nibLocation` stays at its initial `.zero` (the square's top-left).
  Still to do on hardware: nib centering on a real iPhone and on a Duo, and resizability on
  an iPad.

### [ ] 4. Make `ScreenReader` reactive

**Change `ScreenReportingView`:** in `didMoveToWindow`, start KVO on
`window?.windowScene` for `\.effectiveGeometry` (documented as KVO-observable), replacing any
previous observation (and dropping it when `window` is nil). On each change, report the scene's
`screen` metrics exactly as `didMoveToWindow` does now. Keep the initial `didMoveToWindow` report.
Deduplication already happens in `RootFeature` (step 2).

If KVO on `effectiveGeometry` doesn't fire when moving between Duo displays, try
`windowScene(_:didUpdateEffectiveGeometry:)` via the scene delegate or
`registerForTraitChanges`. Record what worked below.

**Verify on the Duo Padiddle simulator:**

1. Launch on the inner display, record a drawing, then fold to the cover display. The drawing is
   kept, centered, and cropped. Spiral radius follows the smaller screen.
2. Unfold. The drawing is unchanged and the full bitmap is visible again.
3. Launch on the cover display, draw, then unfold. The bitmap grows to the inner size, and the old
   drawing sits centered inside it.
4. Erase and export/share still work after a grow (export uses `contextSideLength`).

**Notes:**

### [ ] 5. Wrap up

- While verifying steps 3–4, rotate the device and check whether the drawing stays fixed to the
  hardware every time (see "The drawing sometimes rotates with the UI" in `docs/todo.md`). If it
  does, remove that todo item. If it doesn't, leave it for separate work.

- Remove the "Folding between displays…" section from `docs/todo.md`. Add a short entry to
  `docs/done.md`: the grow-only rule and why (`configure` erases), the viewSize/square coordinate
  gotcha from step 1, and anything surprising from the notes above.
- Delete this plan file.
