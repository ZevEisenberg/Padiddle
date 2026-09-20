import ComposableArchitecture1

@Feature
struct DeviceMotionFeature {
  struct State: Equatable {
    var isMonitoringForSufficientSpin = false
  }

  @CasePathable
  enum Action {
    case start
    case stop
  }

  enum DelegateAction {
    /// The user has spun the device enough that they understand the rotation direction and/or they can see the drawing happening, so we can hide the hints.
    case spunSufficiently
  }

  let delegate: (DelegateAction) throws -> Void

  @Dependency(\.deviceMotionClient) var deviceMotionClient
  @Dependency(\.continuousClock) var clock

  @StoreTaskID private var sufficientSpinTimer

  var body: some FeatureProtocol<State, Action> {
    Update { state, action in
      switch action {
      case .start:
        // Starting motion updates is idempotent and has to happen on every `.start`, but it
        // deliberately does not run under `sufficientSpinTimer`. A later `.start` registering a
        // task under that ID tears down the monitoring loop an earlier `.start` left running, and
        // then nothing is watching for the spin that hides the hints.
        store.addTask {
          await deviceMotionClient.startMotionUpdates()
        }

        if !state.isMonitoringForSufficientSpin {
          state.isMonitoringForSufficientSpin = true

          store.addTask { sufficientSpinTimer.cancel() }
          store.addTask(id: sufficientSpinTimer) {
            for await _ in clock.timer(interval: .seconds(1.0 / 60)) {
              if
                let motion = await deviceMotionClient.deviceMotion(),
                motion.isSufficientMotionToHideHints
              {
                try delegate(.spunSufficiently)
                try store.modify {
                  $0.isMonitoringForSufficientSpin = false
                }
                sufficientSpinTimer.cancel()
              }
            }
          }
        }

      case .stop:
        state.isMonitoringForSufficientSpin = false
        store.addTask { sufficientSpinTimer.cancel() }
        store.addTask {
          await deviceMotionClient.stopMotionUpdates()
        }
      }
    }
  }
}
