import SwiftUI
import Utilities

private enum Design {
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

struct StartHereView: View {
  var body: some View {
    Text(.tutorialStartHere)
      .accessibilityIdentifier("startHereLabel")
      .font(.largeTitle)
      .fontWeight(.medium)
      .foregroundStyle(Color(.Toolbar.StartHere.text))
      .padding(.horizontal, 30)
      .padding(.vertical, 20)
      .background {
        PointDownShape()
          .stroke(Color(.Toolbar.StartHere.stroke))
          .fill(Color(.Toolbar.StartHere.fill))
      }
      .padding(.bottom, Design.arrowBodyHeight + Design.arrowHeadHeight)
      .compositingGroup()
      .shadow(radius: 15, y: 10)
  }
}

#Preview {
  StartHereView()
}
