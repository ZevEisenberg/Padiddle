import Dependencies
import SwiftUI

struct SpinPromptView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    TimelineView(.animation) { context in
      let now = context.date.timeIntervalSinceReferenceDate
      let timeFraction = now.truncatingRemainder(dividingBy: Self.animationDuration) / Self.animationDuration
      let angle = Angle(radians: Self.rotationFraction(forTimeFraction: timeFraction) * 2 * .pi)

      deviceImage
        .rotationEffect(angle)
    }
  }

  @ViewBuilder
  var deviceImage: some View {
    @Dependency(\.deviceClient) var deviceClient
    deviceClient.deviceKind().deviceImage
      .symbolRenderingMode(.palette)
      .foregroundStyle(.foreground, .background)
      .font(.system(size: 300, weight: .ultraLight))
      .overlay {
        Text(.tutorialSpinPrompt)
          .font(.system(size: 30, weight: .medium))
          .foregroundStyle(.blue)
          .multilineTextAlignment(.center)
          .frame(maxWidth: 105)
      }
  }
}

private extension SpinPromptView {
  /// Sigmoid function suggested by Sam Critchlow here: https://www.facebook.com/ZevEisenberg/posts/10209176689033901?comment_id=10209197282908735&comment_tracking=%7B%22tn%22%3A%22R0%22%7D
  static func rotationFraction(forTimeFraction timeFraction: Double) -> Double {
    let a = 6.0
    let numerator = atan(a * (timeFraction - 0.5))
    let denominator = 2 * atan(a / 2)
    return numerator / denominator + 0.5
  }

  static let animationDuration: TimeInterval = 2
}

private struct AnimationProperties {
  var rotation: Angle = .zero
}

#Preview {
  ZStack {
    Text("This should be occluded behind the spinning phone like so")
    SpinPromptView()
  }
}
