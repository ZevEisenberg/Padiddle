//
//  ArrayExtensions.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 9/18/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

extension Array where Element : Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Generator.Element) {
        if let index = indexOf(object) {
            removeAtIndex(index)
        }
    }
}
