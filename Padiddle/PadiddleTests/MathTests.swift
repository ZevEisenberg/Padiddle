//
//  MathTests.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 2/28/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import XCTest

class MathTests: XCTestCase {

    func testCloseEnough() {
        XCTAssertTrue(CGFloat(0.00000001).closeEnough(0))
        XCTAssertTrue(CGFloat(0.00000001).closeEnough(0.00000002))
        XCTAssertFalse(CGFloat(1).closeEnough(2))
        XCTAssertTrue(CGFloat(0).closeEnough(0))
        XCTAssertTrue(CGFloat(1).closeEnough(1))
        XCTAssertTrue(CGFloat(-1).closeEnough(-1))
        XCTAssertTrue(CGFloat(-0.00000001).closeEnough(0.00000001))
    }

    func testReasonableValue() {
        XCTAssertEqual(CGFloat(0).reasonableValue, 0)
        XCTAssertEqual(CGFloat(1E-10).reasonableValue, 0)
        XCTAssertNotEqual(CGFloat(1E-2).reasonableValue, 0)
    }

    func testDegrees() {
        let ε = CGFloat(0.0001)
        XCTAssertEqualWithAccuracy(CGFloat(0).degrees, 0, accuracy: ε)
        XCTAssertEqualWithAccuracy(π.degrees, 180, accuracy: ε)
        XCTAssertEqualWithAccuracy(twoPi.degrees, 360, accuracy: ε)
        XCTAssertEqualWithAccuracy(CGFloat(π / 3).degrees, 60, accuracy: ε)
    }
}
