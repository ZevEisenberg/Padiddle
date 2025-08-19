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
}
