//
//  HelpViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 11/22/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {

    var viewModel = HelpViewModel()

    // Using UIWebView because WKWebView won't talk to the custom NSURLProtocol subclass
    let webView = UIWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.About.string

        webView.backgroundColor = .whiteColor()
        webView.delegate = self
        view.addSubview(webView)
        webView.pinEdgesToMargins(view)
        webView.loadHTMLString(viewModel.html, baseURL: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HelpViewController.typeSizeChanged(_:)), name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.accessibilityIdentifier = "about padiddle"
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        webView.scrollView.flashScrollIndicators()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        coordinator.animateAlongsideTransition(nil, completion: { _ in
            self.webView.scrollView.flashScrollIndicators()
        })
    }

    func typeSizeChanged(note: NSNotification) {
        webView.loadHTMLString(viewModel.html, baseURL: nil)
    }
}

extension HelpViewController: UIWebViewDelegate {
    func webViewDidFinishLoad(webView: UIWebView) {
        webView.scrollView.flashScrollIndicators()
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        switch navigationType {
        case .LinkClicked:
            if let url = request.URL {
                UIApplication.sharedApplication().openURL(url)
            }
            return false
        case .Other, .Reload:
            return true
        default:
            fatalError("Unexpected navigation type \(navigationType)")
        }
    }
}
