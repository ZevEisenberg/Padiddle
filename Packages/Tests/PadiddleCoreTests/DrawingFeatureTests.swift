import ComposableArchitecture1
import CoreGraphics.CGBase
import Testing

@testable import PadiddleCore

@Suite
@MainActor
struct DrawingFeatureTests {
  /// On a non-square screen, a stroke must land on the nib, not shifted by the difference between
  /// the screen and the canvas square.
  @Test
  func strokeStartsUnderTheNibOnANonSquareScreen() async {
    let bitmapContext = BitmapContextClient()
    _ = await bitmapContext.configure(contextSideLength: 844, screenScale: 1)

    @Shared(.isRecording) var isRecording
    $isRecording.withLock { $0 = true }

    var state = DrawingFeature.State()
    state.viewSize = CGSize(width: 390, height: 844)
    state.contextSideLength = 844

    let store = withDependencies {
      $0.bitmapContextClient = bitmapContext
    } operation: {
      TestStore(initialState: state) {
        DrawingFeature()
      }
    }

    // No spin, so the radius is 0 and the nib sits at the center of the square.
    let center = CGPoint(x: 422, y: 422)
    store.send(.processMotion(.zero)) {
      $0.nibLocation = center
      $0.needToMoveNibToNewStartLocation = false
      $0.points = Array(repeating: center, count: 4)
    }

    await store.finish()
  }
}
