import CoreMotion
import Dependencies
import DependenciesMacros
import Synchronization
import Utilities

struct PadiddleDeviceMotion: Hashable, Sendable {
  /// Z-axis rotation rate in radians/second. The sign follows the right hand rule (i.e. if the right hand is wrapped around the Z axis such that the tip of the thumb points toward positive Z, a positive rotation is one toward the tips of the other 4 fingers).
  var rotationRateZ: Double

  /// The yaw of the device in radians.
  var attitudeYaw: Double

  var isSufficientMotionToHideHints: Bool {
    abs(rotationRateZ) > .pi || abs(attitudeYaw) > .pi / 2
  }

  static var zero: Self {
    Self(rotationRateZ: 0, attitudeYaw: 0)
  }
}

@DependencyClient
struct DeviceMotionClient: DependencyKey, Sendable {
  var startMotionUpdates: @MainActor () -> Void
  var stopMotionUpdates: @MainActor () -> Void
  var deviceMotion: @MainActor () -> PadiddleDeviceMotion?
}

@MainActor
private let motionManager = with(CMMotionManager()) {
  $0.deviceMotionUpdateInterval = 1 / 120
}

extension DeviceMotionClient {
  static var liveValue: Self {
    Self(
      startMotionUpdates: {
        let referenceFrame: CMAttitudeReferenceFrame = motionManager.isMagnetometerActive
          ? .xArbitraryCorrectedZVertical
          : .xArbitraryZVertical

        motionManager.startDeviceMotionUpdates(using: referenceFrame)
      },
      stopMotionUpdates: {
        motionManager.stopDeviceMotionUpdates()
      },
      deviceMotion: {
        motionManager.deviceMotion.map {
          PadiddleDeviceMotion(
            rotationRateZ: $0.rotationRate.z,
            attitudeYaw: $0.attitude.yaw
          )
        }
      }
    )
  }
}

extension DependencyValues {
  var deviceMotionClient: DeviceMotionClient {
    get { self[DeviceMotionClient.self] }
    set { self[DeviceMotionClient.self] = newValue }
  }
}
