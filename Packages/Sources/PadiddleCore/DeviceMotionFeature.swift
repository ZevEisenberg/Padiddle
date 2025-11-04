import ComposableArchitecture

@Reducer
struct DeviceMotionFeature {
  struct State: Equatable {
    var isMonitoringForSufficientSpin = false
  }

  @CasePathable
  enum Action {
    case start
    case stop

    case delegate(Delegate)

    @CasePathable
    enum Delegate {
      /// The user has spun the device enough that they understand the rotation direction and/or they can see the drawing happening, so we can hide the hints.
      case spunSufficiently
    }
  }

  @Dependency(\.deviceMotionClient) var deviceMotionClient
  @Dependency(\.continuousClock) var clock

  enum CancelID {
    case sufficientSpinTimer
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .start:
      var actuallyStart = false
      if !state.isMonitoringForSufficientSpin {
        actuallyStart = true
        state.isMonitoringForSufficientSpin = true
      }
      return .run { [isMonitoring = state.isMonitoringForSufficientSpin, actuallyStart] send in
        await deviceMotionClient.startMotionUpdates()
        if actuallyStart {
          guard isMonitoring else {
            return
          }

          for await _ in clock.timer(interval: .seconds(1.0 / 60)) {
            if
              let motion = await deviceMotionClient.deviceMotion(),
              motion.isSufficientMotionToHideHints
            {
              await send(.delegate(.spunSufficiently))
            }
          }
        }
      }
      .cancellable(id: CancelID.sufficientSpinTimer, cancelInFlight: actuallyStart)

    case .stop:
      state.isMonitoringForSufficientSpin = false
      return .merge {
        Effect.cancel(id: CancelID.sufficientSpinTimer)
        Effect.run { _ in
          await deviceMotionClient.stopMotionUpdates()
        }
      }

    case .delegate(.spunSufficiently):
      state.isMonitoringForSufficientSpin = false
      return .cancel(id: CancelID.sufficientSpinTimer)
    }
  }
}
