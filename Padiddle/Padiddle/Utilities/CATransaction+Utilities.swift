//
//  CATransaction+Utilities.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 2/17/19.
//  Copyright © 2019 Zev Eisenberg. All rights reserved.
//

import QuartzCore

extension CATransaction {

    static func performWithoutAnimation(_ block: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        block()
        CATransaction.commit()
    }

}
