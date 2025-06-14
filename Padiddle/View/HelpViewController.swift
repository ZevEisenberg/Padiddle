import Anchorage
import WebKit

class HelpViewController: UIViewController {
  var viewModel = HelpViewModel()

  let webView: WKWebView = {
    let config = WKWebViewConfiguration()
    config.setURLSchemeHandler(HelpImageHandler(), forURLScheme: "asset")
    let webView = WKWebView(frame: .zero, configuration: config)
    return webView
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    title = String(localized: .about)

    webView.backgroundColor = .white
    webView.navigationDelegate = self
    view.addSubview(webView)
    webView.verticalAnchors == view.verticalAnchors
    webView.horizontalAnchors == view.horizontalAnchors
    webView.loadHTMLString(viewModel.html, baseURL: nil)

    NotificationCenter.default.addObserver(self, selector: #selector(HelpViewController.typeSizeChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.accessibilityIdentifier = "about padiddle"
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if !Defaults.snapshotMode {
      webView.scrollView.flashScrollIndicators()
    }
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    if !Defaults.snapshotMode {
      coordinator.animate(alongsideTransition: nil, completion: { _ in
        self.webView.scrollView.flashScrollIndicators()
      })
    }
  }

  @objc func typeSizeChanged(_: NSNotification) {
    webView.loadHTMLString(viewModel.html, baseURL: nil)
  }
}

extension HelpViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
    if !Defaults.snapshotMode {
      webView.scrollView.flashScrollIndicators()
    }
  }

  func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    switch navigationAction.navigationType {
    case .linkActivated:
      if let url = navigationAction.request.url {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
      decisionHandler(.cancel)
    case .other,
         .reload:
      decisionHandler(.allow)
    default:
      fatalError("Unexpected navigation type \(navigationAction.navigationType)")
    }
  }
}
