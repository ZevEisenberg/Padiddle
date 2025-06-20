import Anchorage
import BonMot
import SwiftUI
import UIKit

@available(*, deprecated, renamed: "StartHereViewSwiftUI")
final class StartHereView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)

    let backgroundImage = UIImage(resource: .startHereBackground)

    let backgroundImageView = UIImageView(image: backgroundImage)

    let imageInsets = backgroundImage.capInsets

    let labelInsets = UIEdgeInsets(
      top: imageInsets.top + 0,
      left: imageInsets.left + 30,
      bottom: imageInsets.bottom + 0,
      right: imageInsets.right + 30
    )

    let label = UILabel(axId: "startHereLabel")
    label.numberOfLines = 0
    label.attributedText = String(localized: .tutorialStartHere).styled(with: StringStyle([
      .adapt(.control),
      .font(UIFont.systemFont(ofSize: 30, weight: .medium)),
      .color(UIColor(resource: .tutorialText)),
      .alignment(.center),
    ]))

    addSubview(backgroundImageView)
    addSubview(label)

    backgroundImageView.edgeAnchors == edgeAnchors

    label.edgeAnchors == edgeAnchors + labelInsets

    widthAnchor == backgroundImage.size.width
  }

  @available(*, unavailable) required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private nonisolated
enum Design {
  static let arrowBodyWidth = 17.0
  static let arrowBodyHeight = 24.0

  static let arrowHeadWidth = 50.0
  static let arrowHeadHeight = 30.0
}

struct PointDownShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.addRoundedRect(in: rect, cornerSize: .square(sideLength: 5))
    path.addRect(
      CGRect(
        x: rect.midX - Design.arrowBodyWidth / 2,
        y: rect.height,
        width: Design.arrowBodyWidth,
        height: Design.arrowBodyHeight
      )
    )

    //  1 ______ 2
    //    \    /
    //     \  /
    //      \/
    //      3

    // 1
    path.move(
      to: CGPoint(
        x: rect.midX - Design.arrowHeadWidth / 2,
        y: rect.height + Design.arrowBodyHeight
      )
    )

    // 2
    path.addLine(
      to: CGPoint(
        x: rect.midX + Design.arrowHeadWidth / 2,
        y: rect.height + Design.arrowBodyHeight
      )
    )

    // 3
    path.addLine(
      to: CGPoint(
        x: rect.midX,
        y: rect.height + Design.arrowBodyHeight + Design.arrowHeadHeight
      )
    )

    path.closeSubpath()

    return path
  }
}

struct StartHereViewSwiftUI: View {
  var body: some View {
    Text(.tutorialStartHere)
      .accessibilityIdentifier("startHereLabel")
      .font(.largeTitle)
      .fontWeight(.medium)
      .foregroundStyle(Color(.tutorialText))
      .padding(.horizontal, 30)
      .padding(.vertical, 20)
      .background {
        PointDownShape()
          .stroke(Color(.StartHere.stroke))
          .fill(Color(.StartHere.fill))
      }
      .padding(.bottom, Design.arrowBodyHeight + Design.arrowHeadHeight)
      .compositingGroup()
      .shadow(radius: 15, y: 10)
  }
}

struct StartHereRepresentable: UIViewRepresentable {
  func makeUIView(context: Context) -> StartHereView {
    StartHereView()
  }

  func updateUIView(_: StartHereView, context: Context) {}
}

#Preview {
  VStack {
    StartHereRepresentable()
    StartHereViewSwiftUI()
  }
}
