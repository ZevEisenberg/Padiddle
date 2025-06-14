import Anchorage
import UIKit

class RootViewController: UIViewController {
  let viewModel: RootViewModel
  var pinnedViewController: UIViewController
  var rotatingViewController: UIViewController

  required init(viewModel: RootViewModel, pinnedViewController: UIViewController, rotatingViewController: UIViewController) {
    self.viewModel = viewModel
    self.pinnedViewController = pinnedViewController
    self.rotatingViewController = rotatingViewController
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("\(#function) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white
    view.clipsToBounds = true

    addChild(pinnedViewController)
    addChild(rotatingViewController)

    view.addSubview(pinnedViewController.view)
    view.addSubview(rotatingViewController.view)

    pinnedViewController.didMove(toParent: self)
    rotatingViewController.didMove(toParent: self)

    pinnedViewController.view.centerAnchors == view.centerAnchors

    rotatingViewController.view.edgeAnchors == view.edgeAnchors
  }

  override var prefersStatusBarHidden: Bool {
    true
  }
}
