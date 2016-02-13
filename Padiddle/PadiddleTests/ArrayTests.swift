//
//  ArrayTests.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 1/25/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import XCTest

class ArrayTests: XCTestCase {

    func testRemoveObject() {
        var a1 = [1, 2, 3]
        a1.remove(1)
        XCTAssertEqual(a1, [2, 3])

        var a2 = [Int]()
        a2.remove(1)
        XCTAssertEqual(a2, [])

        var a3 = [3, 4, 5]
        let toRemove = 1
        XCTAssert(!a3.contains(toRemove))
        a3.remove(1)
        XCTAssertEqual(a3, [3, 4, 5])
    }

    func testZippingArraysOfAlmostTheSameLength() {
        let long = ["a", "b", "c", "d", "e"]
        let short = ["1", "2", "3", "4"]

        XCTAssertEqual(long.zip(almostSameLengthArray: short), ["a", "1", "b", "2", "c", "3", "d", "4", "e"])
        XCTAssertEqual(short.zip(almostSameLengthArray: long), ["a", "1", "b", "2", "c", "3", "d", "4", "e"])

        XCTAssertEqual([1].zip(almostSameLengthArray: [Int]()), [1])
        XCTAssertEqual([Int]().zip(almostSameLengthArray: [1]), [1])
    }

    func testTupleEquality() {
        XCTAssertTrue((0, 0) == (0, 0))
        XCTAssertTrue((1, 2) == (1, 2))
        XCTAssertFalse((1, 2) == (2, 3))
        XCTAssertFalse((1, 2) == (2, 1))
    }

    func testDoublets() {
        let empty = [Int]()
        XCTAssertNil(empty.doublets)
        let one = [1]
        XCTAssertNil(one.doublets)

        let array = ["a", "b", "c", "d", "e"]
        let doublets = array.doublets!
        XCTAssertNotNil(doublets)

        let exemplar = [
            ("a", "b"),
            ("b", "c"),
            ("c", "d"),
            ("d", "e"),
        ]

        let zipped = zip(doublets, exemplar)

        for pair in zipped {
            XCTAssertTrue(pair.0 == pair.1)
            XCTAssertEqual(pair.0.0, pair.1.0)
            XCTAssertEqual(pair.0.1, pair.1.1)
        }
    }
}

func == <T: Equatable> (tuple1: (T, T), tuple2: (T, T)) -> Bool {
    return (tuple1.0 == tuple2.0) && (tuple1.1 == tuple2.1)
}
