import ComposableArchitecture1
import Testing

@testable import PadiddleCore

@MainActor
@Suite
struct DeviceMotionTests {
  @Test
  func startAndStopWithNoSpin() async throws {
    let startMotionCallCount = LockIsolated(0)
    var stopMotionCallCount = 0

    let clock = TestClock()

    let store = withDependencies {
      $0.continuousClock = clock
      $0.deviceMotionClient = .init(
        startMotionUpdates: {
          startMotionCallCount.withValue { $0 += 1 }
        },
        stopMotionUpdates: {
          stopMotionCallCount += 1
        },
        deviceMotion: {
          .zero
        }
      )
    } operation: {
      TestStore(initialState: .init()) {
        DeviceMotionFeature(delegate: { _ in })
      }
    }

    #expect(startMotionCallCount.value == 0)
    store.send(.start) {
      $0.isMonitoringForSufficientSpin = true
    }
    #expect(startMotionCallCount.value == 1)

    await clock.advance(by: .seconds(1))

    #expect(stopMotionCallCount == 0)
    store.send(.stop) {
      $0.isMonitoringForSufficientSpin = false
    }
    #expect(stopMotionCallCount == 1)

    #expect(startMotionCallCount.value == 1) // no change

    try await clock.checkSuspension()
  }

  @Test
  func happyPath() async throws {
    var startMotionCallCount = 0
    var stopMotionCallCount = 0
    var motionToGet: PadiddleDeviceMotion?

    let clock = TestClock()

    let store = withDependencies {
      $0.continuousClock = clock
      $0.deviceMotionClient.startMotionUpdates = {
        startMotionCallCount += 1
      }
      $0.deviceMotionClient.stopMotionUpdates = {
        stopMotionCallCount += 1
      }
      $0.deviceMotionClient.deviceMotion = { motionToGet }
    } operation: {
      TestStore(initialState: .init()) {
        DeviceMotionFeature(delegate: { _ in })
      }
    }

    #expect(startMotionCallCount == 0)
    store.send(.start) {
      $0.isMonitoringForSufficientSpin = true
    }

    #expect(startMotionCallCount == 1)

    await clock.advance(by: .seconds(0.5))

    motionToGet = PadiddleDeviceMotion(rotationRateZ: 4, attitudeYaw: 2)

    await clock.advance(by: .seconds(1.0 / 60))

    store.expect {
      $0.isMonitoringForSufficientSpin = false
    }

    await clock.advance()

    #expect(startMotionCallCount == 1) // no change

    #expect(stopMotionCallCount == 0)
    store.send(.stop)
    #expect(stopMotionCallCount == 1)

    try await clock.checkSuspension()
  }

  /// A second `.start` (the app sends one per `screenChanged`) used to register a task under the
  /// monitoring loop's `@StoreTaskID` and tear the loop down, so nothing was left watching for the
  /// spin that hides the hints.
  @Test
  func secondStartDoesNotKillTheMonitoringLoop() async throws {
    let motionToGet = LockIsolated<PadiddleDeviceMotion?>(.zero)
    let spunSufficientlyCount = LockIsolated(0)

    let clock = TestClock()

    let store = withDependencies {
      $0.continuousClock = clock
      $0.deviceMotionClient.startMotionUpdates = {}
      $0.deviceMotionClient.stopMotionUpdates = {}
      $0.deviceMotionClient.deviceMotion = { motionToGet.value }
    } operation: {
      TestStore(initialState: .init()) {
        DeviceMotionFeature(delegate: { _ in
          spunSufficientlyCount.withValue { $0 += 1 }
        })
      }
    }

    store.send(.start) {
      $0.isMonitoringForSufficientSpin = true
    }

    await clock.advance(by: .seconds(0.5))

    // A second `.start` while already monitoring must be a no-op for the loop.
    store.send(.start)

    await clock.advance(by: .seconds(0.5))

    motionToGet.setValue(PadiddleDeviceMotion(rotationRateZ: 4, attitudeYaw: 2))

    await clock.advance(by: .seconds(1.0 / 60))

    store.expect {
      $0.isMonitoringForSufficientSpin = false
    }
    #expect(spunSufficientlyCount.value == 1)

    await clock.advance()

    store.send(.stop)

    try await clock.checkSuspension()
  }
}
