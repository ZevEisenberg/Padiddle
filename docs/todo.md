# Todo

Open work and open questions. Finished items move to [done.md](done.md).

## Re-prompt on resume after a completed recording

Once the user has recorded and stopped, `HintFeature.State.hintState` is `.waitToShowSpinPrompt`,
and the guard in `.onTrigger(store.start)` only restarts the countdown from `.waitToShowRecordPrompt`.
So foregrounding the app, or dismissing a sheet, will **not** bring the record prompt back for
someone who used the app earlier and is returning cold.

This matches the behavior on `main`, so it was preserved deliberately during the TCA 2 port rather
than changed silently. But the app is unintuitive enough that a returning user probably does need
reminding again — "first tap the spin button, then spin your device."

Open question: what should reset it? Options, roughly in order of how much they change:

- Let `start` also restart from `.waitToShowSpinPrompt` (one-line change to the guard) — but that
  re-prompts on every sheet dismissal too, which is probably too chatty.
- Reset to `.waitToShowRecordPrompt` only on foreground, and only after some gap (say, the app was
  backgrounded for more than a few minutes).
- Persist "this user has seen the prompts and spun successfully" and stop reminding entirely once
  they've demonstrated they understand.

`.disabled` already exists for the last case — it's set from `spunEnoughToHidePrompt` — but it's
in-memory per launch, not persisted.

### Decided: show the spin prompt on *every* record-without-spin

Observing real users, people don't get this app the first couple of times — that's fine, it's
esoteric, but they need a nudge. So the spin prompt should reappear **every time** the user taps
record and then doesn't spin, not just the first time per launch.

That means `spunEnoughToHidePrompt` should stop being a one-way latch to `.disabled`. The natural
shape: keep `.disabled` for the current recording only, and let `isRecordingChanged(true)` put the
state back to `.waitToShowSpinPrompt` the way it already does — i.e. drop the `.disabled` terminal
state, or make `.onTrigger(store.spunEnoughToHidePrompt)` set something that `isRecordingChanged`
clears.

Watch out for two things when doing this:

- `HintFeature`'s `spunEnoughToHidePrompt` handler currently cancels `spunEnoughToHideSpinPrompt`,
  which is the `@StoreTaskID` of the `isRecording` *observation loop* — so today the feature stops
  observing `isRecording` for good after a successful spin. That cancel has to go, or the prompt
  can never come back.
- `DeviceMotionFeature` sets `isMonitoringForSufficientSpin = false` after a successful spin and
  only restarts monitoring on the next `.start`. It needs to re-arm per recording session too.

## Reduce the action-log noise the TCA 2 way

`RootView.swift` carries a `#warning`: the old `_printChanges` printer that filtered out the noisy
per-frame `.drawing(.updateMotion)` / `.drawing(.processMotion)` actions is commented out, and
`_logChanges()` currently logs everything. TCA 2 has action/trigger/delegate/event/private
distinctions that should make most of that noise not be actions at all — redo the filtering by
moving the per-frame motion path off the action channel instead of filtering it after the fact.

## Exercise the new hint re-triggers by hand

The two new re-trigger paths are covered by reasoning, not by a test that drives real view
lifecycle:

- foregrounding the app (`RootView`, `scenePhase == .active` → `try store.toolbar.hint.start()`)
- dismissing a sheet or popover over the toolbar (`ToolbarView`, `.onChange(of: store.destination)`)

Worth running on device once to confirm the prompt actually reappears, and that it doesn't
double-fire when a sheet dismissal and a foreground happen close together.

## Revisit the TCA26 pin

`Packages/Package.swift` pins `TCA26` to `branch: "main"`, which is a moving target — the port
already had to chase one breaking change mid-stream. Switch to an exact tag once the beta publishes
one.
