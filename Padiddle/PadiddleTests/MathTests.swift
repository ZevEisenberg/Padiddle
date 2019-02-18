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
        XCTAssertTrue(CGFloat(0.00000001).closeEnough(to: 0))
        XCTAssertTrue(CGFloat(0.00000001).closeEnough(to: 0.00000002))
        XCTAssertFalse(CGFloat(1).closeEnough(to: 2))
        XCTAssertTrue(CGFloat(0).closeEnough(to: 0))
        XCTAssertTrue(CGFloat(1).closeEnough(to: 1))
        XCTAssertTrue(CGFloat(-1).closeEnough(to: -1))
        XCTAssertTrue(CGFloat(-0.00000001).closeEnough(to: 0.00000001))
    }

    func testReasonableValue() {
        XCTAssertEqual(CGFloat(0).reasonableValue, 0)
        XCTAssertEqual(CGFloat(1E-10).reasonableValue, 0)
        XCTAssertNotEqual(CGFloat(1E-2).reasonableValue, 0)
    }

}
