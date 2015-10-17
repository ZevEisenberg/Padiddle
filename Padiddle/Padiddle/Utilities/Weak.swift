//
//  Weak.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 10/17/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

class Weak<T: AnyObject> {
    weak var value: T?
    init(value: T) {
        self.value = value
    }
}
