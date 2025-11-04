import ComposableArchitecture
import Testing

@testable import PadiddleCore

@MainActor
@Suite
struct DeviceMotionTests {
  @Test
  func startAndStopWithNoSpin() async throws {
    var startMotionCallCount = 0
    var stopMotionCallCount = 0

    let clock = TestClock()

    let store = TestStore(initialState: .init()) {
      DeviceMotionFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.deviceMotionClient = .init(
        startMotionUpdates: {
          startMotionCallCount += 1
        },
        stopMotionUpdates: {
          stopMotionCallCount += 1
        },
        deviceMotion: {
          .zero
        }
      )
    }

    #expect(startMotionCallCount == 0)
    await store.send(.start) {
      $0.isMonitoringForSufficientSpin = true
    }
    #expect(startMotionCallCount == 1)

    await clock.advance(by: .seconds(1))

    #expect(stopMotionCallCount == 0)
    await store.send(.stop) {
      $0.isMonitoringForSufficientSpin = false
    }
    #expect(stopMotionCallCount == 1)

    #expect(startMotionCallCount == 1) // no change

    try await clock.checkSuspension()
  }

  @Test
  func happyPath() async throws {
    var startMotionCallCount = 0
    var stopMotionCallCount = 0
    var motionToGet: PadiddleDeviceMotion?

    let clock = TestClock()

    let store = TestStore(initialState: .init()) {
      DeviceMotionFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.deviceMotionClient.startMotionUpdates = {
        startMotionCallCount += 1
      }
      $0.deviceMotionClient.stopMotionUpdates = {
        stopMotionCallCount += 1
      }
      $0.deviceMotionClient.deviceMotion = { motionToGet }
    }

    #expect(startMotionCallCount == 0)
    await store.send(.start) {
      $0.isMonitoringForSufficientSpin = true
    }

    #expect(startMotionCallCount == 1)

    await clock.advance(by: .seconds(0.5))

    motionToGet = PadiddleDeviceMotion(rotationRateZ: 4, attitudeYaw: 2)

    await clock.advance(by: .seconds(1.0 / 60))

    await store.receive(\.delegate.spunSufficiently, timeout: .seconds(1)) {
      $0.isMonitoringForSufficientSpin = false
    }

    await clock.advance()

    #expect(startMotionCallCount == 1) // no change

    #expect(stopMotionCallCount == 0)
    await store.send(.stop)
    #expect(stopMotionCallCount == 1)

    try await clock.checkSuspension()
  }
}
