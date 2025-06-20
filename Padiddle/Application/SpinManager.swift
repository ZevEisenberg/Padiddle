import CoreMotion
import UIKit

@MainActor
protocol SufficientSpinDelegate: AnyObject {
  /// After you call `startMonitoringForSufficientSpin()`, this method may be called
  /// on the delegate no more than one time at some point in the future. Subsequent
  /// calls to `startMonitoringForSufficientSpin()` will reset the spin counter,
  /// even if the previous request to monitor for sufficient spin has not yet been fulfilled.
  func spunEnough()
}

final class SpinManager: UIResponder {
  // Public Properties

  weak var sufficientSpinDelegate: SufficientSpinDelegate?

  var deviceMotion: CMDeviceMotion? {
    motionManager.deviceMotion
  }

  // Private Properties

  private let motionManager: CMMotionManager = {
    let manager = CMMotionManager()
    manager.deviceMotionUpdateInterval = 1.0 / 120.0
    return manager
  }()

  private var isMonitoringForSufficientSpin = false

  private var sufficientSpinTimer: Timer?
}

// MARK: Public Methods

extension SpinManager {
  func startMotionUpdates() {
    let referenceFrame: CMAttitudeReferenceFrame = motionManager.isMagnetometerActive
      ? .xArbitraryCorrectedZVertical
      : .xArbitraryZVertical

    motionManager.startDeviceMotionUpdates(using: referenceFrame)
  }

  func stopMotionUpdates() {
    motionManager.stopDeviceMotionUpdates()
  }

  func startMonitoringForSufficientSpin() {
    #if targetEnvironment(simulator)
    let result = becomeFirstResponder()
    print("become first responder:", result)
    #endif

    isMonitoringForSufficientSpin = true

    let timer = Timer(fireAt: Date(), interval: 1.0 / 60.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    sufficientSpinTimer = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  func stopMonitoringForSufficientSpin() {
    #if targetEnvironment(simulator)
    resignFirstResponder()
    #endif

    isMonitoringForSufficientSpin = false
    sufficientSpinTimer?.invalidate()
    sufficientSpinTimer = nil
  }

  override var canBecomeFirstResponder: Bool {
    #if targetEnvironment(simulator)
    true
    #else
    false
    #endif
  }

  override var next: UIResponder? {
    #if targetEnvironment(simulator)
    UIApplication.shared.connectedScenes.first as? UIWindowScene
    #else
    nil
    #endif
  }

  override func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?) {
    #if targetEnvironment(simulator)
    if motion == .motionShake {
      // can't spin the simulator, so shake to to simulate it
      respondToSufficientMotion()
    }
    #endif
  }
}

private extension SpinManager {
  @objc func timerFired() {
    if isMonitoringForSufficientSpin,
       let motion = motionManager.deviceMotion,
       abs(motion.rotationRate.z) > .pi
       || abs(motion.attitude.yaw) > .pi / 2
    {
      respondToSufficientMotion()
    }
  }

  func respondToSufficientMotion() {
    isMonitoringForSufficientSpin = false
    sufficientSpinTimer?.invalidate()
    sufficientSpinTimer = nil
    sufficientSpinDelegate?.spunEnough()
  }
}
