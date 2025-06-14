import PlaygroundSupport
import UIKit

final class PathView: UIView {
  private var path: CGPath?

  static func smoothedPathSegment(points: [CGPoint]) -> CGPath {
    assert(points.count == 4)

    let p0 = points[3]
    let p1 = points[2]
    let p2 = points[1]
    let p3 = points[0]

    let c1 = CGPoint(
      x: (p0.x + p1.x) / 2.0,
      y: (p0.y + p1.y) / 2.0
    )
    let c2 = CGPoint(
      x: (p1.x + p2.x) / 2.0,
      y: (p1.y + p2.y) / 2.0
    )
    let c3 = CGPoint(
      x: (p2.x + p3.x) / 2.0,
      y: (p2.y + p3.y) / 2.0
    )

    let len1 = sqrt(pow(p1.x - p0.x, 2.0) + pow(p1.y - p0.y, 2.0))
    let len2 = sqrt(pow(p2.x - p1.x, 2.0) + pow(p2.y - p1.y, 2.0))
    let len3 = sqrt(pow(p3.x - p2.x, 2.0) + pow(p3.y - p2.y, 2.0))

    let divisor1 = len1 + len2
    let divisor2 = len2 + len3

    let k1 = len1 / divisor1
    let k2 = len2 / divisor2

    let m1 = CGPoint(
      x: c1.x + (c2.x - c1.x) * k1,
      y: c1.y + (c2.y - c1.y) * k1
    )
    let m2 = CGPoint(
      x: c2.x + (c3.x - c2.x) * k2,
      y: c2.y + (c3.y - c2.y) * k2
    )

    // Resulting control points. Here smooth_value is mentioned
    // above coefficient K whose value should be in range [0...1].
    let smoothValue = CGFloat(1.0)

    let ctrl1: CGPoint = {
      let x = m1.x + (c2.x - m1.x) * smoothValue + p1.x - m1.x
      let y = m1.y + (c2.y - m1.y) * smoothValue + p1.y - m1.y
      return CGPoint(x: x, y: y)
    }()
    let ctrl2: CGPoint = {
      let x = m2.x + (c2.x - m2.x) * smoothValue + p2.x - m2.x
      let y = m2.y + (c2.y - m2.y) * smoothValue + p2.y - m2.y
      return CGPoint(x: x, y: y)
    }()

    let pathSegment = CGMutablePath()
    pathSegment.move(to: p1)
    pathSegment.addCurve(to: p2, control1: ctrl1, control2: ctrl2)

    return pathSegment
  }

  func update(with points: [CGPoint]) {
    assert(points.count == 4)
    let mutablePath = CGMutablePath()
    mutablePath.addPath(PathView.smoothedPathSegment(points: points))
    path = mutablePath
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    guard let path else {
      return
    }
    let uiPath = UIBezierPath(cgPath: path)
    uiPath.lineWidth = 2
    UIColor.red.setFill()
    uiPath.stroke()
  }
}

final class MovableView: UIView {
  private let dragNotifier: () -> Void

  init(frame: CGRect, dragNotifier: @escaping () -> Void) {
    self.dragNotifier = dragNotifier
    super.init(frame: frame)
    isOpaque = false
    let pan = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    addGestureRecognizer(pan)
  }

  @available(*, unavailable) required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_: CGRect) {
    UIColor.blue.setFill()
    UIBezierPath(ovalIn: bounds).fill()
  }

  @objc func panned(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .changed:
      let location = sender.location(in: superview!)
      center = location
      dragNotifier()
    default:
      break
    }
  }
}

let pathView = PathView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
pathView.backgroundColor = .lightGray

let positions = [
  CGPoint(x: 20, y: 20),
  CGPoint(x: 50, y: 30),
  CGPoint(x: 120, y: 20),
  CGPoint(x: 180, y: 50),
]

let notifier = {
  let centers = pathView.subviews.map { $0.center }
  pathView.update(with: centers)
}

let movables = positions.map { point in
  MovableView(frame: CGRect(origin: point, size: CGSize(width: 25, height: 25)), dragNotifier: notifier)
}

for view in movables {
  pathView.addSubview(view)
}

notifier()

PlaygroundPage.current.liveView = pathView
