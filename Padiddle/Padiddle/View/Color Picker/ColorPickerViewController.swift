//
//  ColorPickerViewController.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import UIKit

class ColorPickerViewController: UIViewController {
    init(viewModel: ColorPickerViewModel) {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("Color Settings", comment: "Title of a view that lets you choose a color scheme")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("\(__FUNCTION__) has not been implemented")
    }
}
