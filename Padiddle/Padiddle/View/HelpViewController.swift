//
//  HelpViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 11/22/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import Anchorage

class HelpViewController: UIViewController {

    var viewModel = HelpViewModel()

    // Using UIWebView because WKWebView won't talk to the custom NSURLProtocol subclass
    let webView = UIWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.about.string

        webView.backgroundColor = .white
        webView.delegate = self
        view.addSubview(webView)
        webView.verticalAnchors == view.layoutMarginsGuide.verticalAnchors
        webView.horizontalAnchors == view.horizontalAnchors
        webView.loadHTMLString(viewModel.html, baseURL: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(HelpViewController.typeSizeChanged(_:)), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
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

    func typeSizeChanged(_ note: NSNotification) {
        webView.loadHTMLString(viewModel.html, baseURL: nil)
    }

}

extension HelpViewController: UIWebViewDelegate {

    func webViewDidFinishLoad(_ webView: UIWebView) {
        if !Defaults.snapshotMode {
            webView.scrollView.flashScrollIndicators()
        }
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        switch navigationType {
        case .linkClicked:
            if let url = request.url {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return false
        case .other, .reload:
            return true
        default:
            fatalError("Unexpected navigation type \(navigationType)")
        }
    }

}
