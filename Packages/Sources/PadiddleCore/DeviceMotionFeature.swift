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

  let delegate: (DelegateAction) -> Void

  @Dependency(\.deviceMotionClient) var deviceMotionClient
  @Dependency(\.continuousClock) var clock

  @StoreTaskID private var sufficientSpinTimer

  var body: some FeatureProtocol<State, Action> {
    Update { state, action in
      switch action {
      case .start:
        var actuallyStart = false
        if !state.isMonitoringForSufficientSpin {
          actuallyStart = true
          state.isMonitoringForSufficientSpin = true
        }

        if actuallyStart {
          store.addTask { sufficientSpinTimer.cancel() }
        }

        store.addTask(id: sufficientSpinTimer) { [actuallyStart] in
          await deviceMotionClient.startMotionUpdates()
          if actuallyStart {
            guard store.isMonitoringForSufficientSpin else {
              return
            }

            for await _ in clock.timer(interval: .seconds(1.0 / 60)) {
              if
                let motion = await deviceMotionClient.deviceMotion(),
                motion.isSufficientMotionToHideHints
              {
                delegate(.spunSufficiently)
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
