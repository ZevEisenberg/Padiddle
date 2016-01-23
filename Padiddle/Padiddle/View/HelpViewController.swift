//
//  HelpViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 11/22/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit
import WebKit

class HelpViewController: UIViewController {

    var viewModel = HelpViewModel()

    let webView = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Color Settings", comment: "Title of a view that lets you choose a color scheme")

        view.addSubview(webView)
        webView.pinEdgesToMargins(view)
        webView.loadHTMLString(viewModel.html, baseURL: nil)
    }
}
