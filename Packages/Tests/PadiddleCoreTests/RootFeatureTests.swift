import ComposableArchitecture1
import CoreGraphics.CGBase
import Models
import Synchronization
import Testing

@testable import PadiddleCore

@Suite
@MainActor
struct RootFeatureTests {
  @Test
  func appLifecycle() async {
    var startMotionUpdatesCallCount = 0
    var stopMotionUpdatesCallCount = 0

    let store = withDependencies {
      $0.continuousClock = ImmediateClock()
      $0.deviceMotionClient.startMotionUpdates = {
        startMotionUpdatesCallCount += 1
      }
      $0.deviceMotionClient.stopMotionUpdates = {
        stopMotionUpdatesCallCount += 1
      }
    } operation: {
      TestStore(initialState: RootFeature.State()) {
        RootFeature()
      } changes: {
        // Mounting the toolbar starts the hint reminder.
        $0.toolbar.hint.hintState = .waitToShowRecordPrompt
      }
    }

    store.send(
      .screenChanged(
        ScreenMetrics(
          size: CGSize(width: 100, height: 100),
          scale: 2
        )
      )
    ) {
      $0.drawing.contextSideLength = 100
      $0.drawing.viewSize = CGSize(width: 100, height: 100)
    }

    // The clock is immediate, so the reminder countdown elapses right away.
    await store.receive(\.toolbar.hint.showRecordPrompt) {
      $0.toolbar.hint.hintState = .promptForRecord
    }

    await store.receive(\.deviceMotion.start) {
      $0.deviceMotion.isMonitoringForSufficientSpin = true
    }

    #expect(startMotionUpdatesCallCount == 1)

    store.send(.scenePhaseChanged(.inactive))

    await store.receive(\.deviceMotion.stop) {
      $0.deviceMotion.isMonitoringForSufficientSpin = false
    }

    #expect(stopMotionUpdatesCallCount == 1)

    await store.dismount()
  }

  @Test
  func stopRecordingBeforeSpinPromptShows() async {
    var startMotionUpdatesCallCount = 0
    var stopMotionUpdatesCallCount = 0

    let clock = TestClock()

    let store = withDependencies {
      $0.continuousClock = clock
      $0.deviceMotionClient.startMotionUpdates = {
        startMotionUpdatesCallCount += 1
      }
      $0.deviceMotionClient.stopMotionUpdates = {
        stopMotionUpdatesCallCount += 1
      }
    } operation: {
      TestStore(initialState: RootFeature.State()) {
        RootFeature()
      } changes: {
        // Mounting the toolbar starts the hint reminder.
        $0.toolbar.hint.hintState = .waitToShowRecordPrompt
      }
    }

    store.send(
      .screenChanged(
        ScreenMetrics(
          size: CGSize(width: 100, height: 100),
          scale: 2
        )
      )
    ) {
      $0.drawing.contextSideLength = 100
      $0.drawing.viewSize = CGSize(width: 100, height: 100)
    }

    await store.receive(\.deviceMotion.start) {
      $0.deviceMotion.isMonitoringForSufficientSpin = true
    }

    #expect(startMotionUpdatesCallCount == 1)

    store.send(.toolbar(.recordButtonTapped)) {
      $0.toolbar.isRecording = true
    }

    await store.receive(\.toolbar.hint.isRecordingChanged) {
      $0.toolbar.hint.hintState = .waitToShowSpinPrompt
    }

    await clock.advance(by: .seconds(2)) // not enough for prompt to show

    store.send(.toolbar(.recordButtonTapped)) {
      $0.toolbar.isRecording = false
    }

    await store.receive(\.toolbar.hint.isRecordingChanged)

    await clock.advance(by: .seconds(2)) // enough time for prompt to show if it were going to

    // n.b. I never actually got this test to fail, but I fixed the issue it was supposed to test, and who knows, maybe it'll catch it or some other regression if it crops up again
    #expect(store.toolbar.hint.hintState == .waitToShowSpinPrompt)

    // tear down
    store.send(.scenePhaseChanged(.inactive))

    await store.receive(\.deviceMotion.stop) {
      $0.deviceMotion.isMonitoringForSufficientSpin = false
    }

    #expect(stopMotionUpdatesCallCount == 1)

    await store.dismount()
  }

  @Test
  func spinningHidesSpinPrompt() async {
    let clock = TestClock()
    let motionToGet = LockIsolated<PadiddleDeviceMotion?>(.zero)

    let store = withDependencies {
      $0.continuousClock = clock
      $0.deviceMotionClient.startMotionUpdates = {}
      $0.deviceMotionClient.stopMotionUpdates = {}
      $0.deviceMotionClient.deviceMotion = { motionToGet.value }
    } operation: {
      TestStore(initialState: RootFeature.State()) {
        RootFeature()
      } changes: {
        // Mounting the toolbar starts the hint reminder.
        $0.toolbar.hint.hintState = .waitToShowRecordPrompt
      }
    }

    store.send(
      .screenChanged(
        ScreenMetrics(
          size: CGSize(width: 100, height: 100),
          scale: 2
        )
      )
    ) {
      $0.drawing.contextSideLength = 100
      $0.drawing.viewSize = CGSize(width: 100, height: 100)
    }

    // Configuring the bitmap context is async, so `.start` can take a moment to land.
    await store.receive(\.deviceMotion.start, timeout: .seconds(1)) {
      $0.deviceMotion.isMonitoringForSufficientSpin = true
    }

    store.send(.toolbar(.recordButtonTapped)) {
      $0.toolbar.isRecording = true
    }

    await store.receive(\.toolbar.hint.isRecordingChanged) {
      $0.toolbar.hint.hintState = .waitToShowSpinPrompt
    }

    await clock.advance(by: HintFeature.Design.waitForSpinTimeout)

    await store.receive(\.toolbar.hint.showSpinPrompt) {
      $0.toolbar.hint.hintState = .promptForSpin
    }

    // The user finally spins the device.
    motionToGet.setValue(PadiddleDeviceMotion(rotationRateZ: 4, attitudeYaw: 2))

    await clock.advance(by: .seconds(1.0 / 60))

    store.expect {
      $0.deviceMotion.isMonitoringForSufficientSpin = false
      $0.toolbar.hint.hintState = .disabled
    }

    // tear down
    store.send(.scenePhaseChanged(.inactive))

    await store.receive(\.deviceMotion.stop)

    await store.dismount()
  }
}
