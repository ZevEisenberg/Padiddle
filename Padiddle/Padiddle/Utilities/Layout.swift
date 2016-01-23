//
//  Layout.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/22/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import UIKit

extension UIView {
    func pinEdges(parentView: UIView) {
        assert(self.isDescendantOfView(parentView))
        assert(translatesAutoresizingMaskIntoConstraints, "No need to disable this manually any more")

        translatesAutoresizingMaskIntoConstraints = false

        self.topAnchor.constraintEqualToAnchor(parentView.topAnchor).active = true
        self.leadingAnchor.constraintEqualToAnchor(parentView.leadingAnchor).active = true
        self.bottomAnchor.constraintEqualToAnchor(parentView.bottomAnchor).active = true
        self.trailingAnchor.constraintEqualToAnchor(parentView.trailingAnchor).active = true
    }

    func pinEdgesToMargins(parentView: UIView) {
        assert(self.isDescendantOfView(parentView))
        assert(translatesAutoresizingMaskIntoConstraints, "No need to disable this manually any more")

        translatesAutoresizingMaskIntoConstraints = false


        self.topAnchor.constraintEqualToAnchor(parentView.layoutMarginsGuide.topAnchor).active = true
        self.bottomAnchor.constraintEqualToAnchor(parentView.layoutMarginsGuide.bottomAnchor).active = true

        self.leadingAnchor.constraintEqualToAnchor(parentView.leadingAnchor).active = true
        self.trailingAnchor.constraintEqualToAnchor(parentView.trailingAnchor).active = true
    }
}
