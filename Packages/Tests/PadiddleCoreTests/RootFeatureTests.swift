import ComposableArchitecture
import CoreGraphics.CGBase
import Models
import Testing

@testable import PadiddleCore

@Suite
@MainActor
struct RootFeatureTests {
  @Test
  func appLifecycle() async {
    var startMotionUpdatesCallCount = 0
    var stopMotionUpdatesCallCount = 0

    let store = TestStore(initialState: RootFeature.State()) {
      RootFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.deviceMotionClient.startMotionUpdates = {
        startMotionUpdatesCallCount += 1
      }
      $0.deviceMotionClient.stopMotionUpdates = {
        stopMotionUpdatesCallCount += 1
      }
    }

    await store.send(
      .screenChanged(
        ScreenMetrics(
          size: CGSize(width: 100, height: 100),
          scale: 2
        )
      )
    )

    await store.receive(\.deviceMotion.start) {
      $0.deviceMotion.isMonitoringForSufficientSpin = true
    }

    #expect(startMotionUpdatesCallCount == 1)

    await store.send(\.scenePhaseChanged, .inactive)

    await store.receive(\.deviceMotion.stop) {
      $0.deviceMotion.isMonitoringForSufficientSpin = false
    }

    #expect(stopMotionUpdatesCallCount == 1)
  }

  @Test
  func stopRecordingBeforeSpinPromptShows() async {
    var startMotionUpdatesCallCount = 0
    var stopMotionUpdatesCallCount = 0

    let clock = TestClock()

    let store = TestStore(initialState: RootFeature.State()) {
      RootFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.deviceMotionClient.startMotionUpdates = {
        startMotionUpdatesCallCount += 1
      }
      $0.deviceMotionClient.stopMotionUpdates = {
        stopMotionUpdatesCallCount += 1
      }
    }

    await store.send(
      .screenChanged(
        ScreenMetrics(
          size: CGSize(width: 100, height: 100),
          scale: 2
        )
      )
    )

    await store.receive(\.deviceMotion.start) {
      $0.deviceMotion.isMonitoringForSufficientSpin = true
    }

    #expect(startMotionUpdatesCallCount == 1)

    await store.send(.toolbar(.recordButtonTapped)) {
      $0.toolbar.$isRecording.withLock { $0 = true }
    }

    await clock.advance(by: .seconds(2)) // not enough for prompt to show

    await store.send(.toolbar(.recordButtonTapped)) {
      $0.toolbar.$isRecording.withLock { $0 = false }
    }

    await clock.advance(by: .seconds(2)) // enough time for prompt to show if it were going to

    // n.b. I never actually got this test to fail, but I fixed the issue it was supposed to test, and who knows, maybe it'll catch it or some other regression if it crops up again

    // tear down
    await store.send(\.scenePhaseChanged, .inactive)

    await store.receive(\.deviceMotion.stop) {
      $0.deviceMotion.isMonitoringForSufficientSpin = false
    }

    #expect(stopMotionUpdatesCallCount == 1)
  }
}
