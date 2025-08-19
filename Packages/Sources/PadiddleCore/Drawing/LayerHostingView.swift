import SwiftUI
import UIKit

struct LayerHostingViewRepresentable: UIViewRepresentable {
  let hostedLayer: CALayer

  func makeUIView(context: Context) -> LayerHostingView {
    LayerHostingView(hostedLayer: hostedLayer)
  }

  func updateUIView(_ uiView: LayerHostingView, context: Context) {
    assert(uiView.layer !== hostedLayer, "hostedLayer should be a singleton, and should not change after initialization")
  }
}

final class LayerHostingView: UIView {
  let hostedLayer: CALayer

  required init(hostedLayer: CALayer) {
    self.hostedLayer = hostedLayer
    super.init(frame: .zero)
    layer.addSublayer(hostedLayer)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    hostedLayer.bounds = bounds
    hostedLayer.anchorPoint = .zero
    hostedLayer.position = .zero
    super.layoutSubviews()
  }
}
