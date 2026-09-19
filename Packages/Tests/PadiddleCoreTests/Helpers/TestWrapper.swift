import ComposableArchitecture1

/// TCA `Feature`s will only report `isPresented == true` if they are wrapped in another feature, so we can wrap them in `TestWrapper` if their functionality depends on their being presented.
@Feature
struct TestWrapper<Wrapped: FeatureProtocol> {
  let wrapped: Wrapped

  init(_ wrapped: Wrapped) {
    self.wrapped = wrapped
  }

  struct State {
    var wrapped: Wrapped.State
  }

  enum Action {
    case wrapped(Wrapped.Action)
  }

  var body: some FeatureProtocol<State, Action> {
    Scope(\.wrapped, action: \.wrapped) {
      wrapped
    }
  }
}

// public init<State, Action>(
//  initialState: State,
//  feature: () -> Subject,
//  fileID: StaticString = #fileID,
//  filePath: StaticString = #filePath,
//  line: UInt = #line,
//  column: UInt = #column
// ) where Subject.State == State, Subject.Action == Action {

extension TestStore {
  convenience init<
    Wrapped: FeatureProtocol
  >(
    initialWrappedState: Wrapped.State,
    wrappedFeature: () -> Wrapped,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  )
    where Subject == TestWrapper<Wrapped>
  {
    self.init(initialState: .init(wrapped: initialWrappedState), feature: {
      Subject(wrappedFeature())
    }, fileID: fileID, filePath: filePath, line: line, column: column)
  }
}
