//
//  GeometryTests.swift
//  PadiddleTests
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

@testable import Padiddle
import XCTest

let accuracy = 0.00001

class PadiddleTests: XCTestCase {

    func testDistanceBetweenPoints() {
        let p1 = CGPoint.zero
        XCTAssertEqual(Double(CGPoint.distanceBetween(p1, p1)), 0.0, accuracy: accuracy)

        let p2 = CGPoint(x: 10, y: 10)
        let p3 = CGPoint(x: 13, y: 14)
        XCTAssertEqual(Double(CGPoint.distanceBetween(p2, p3)), 5.0, accuracy: accuracy)

        let p4 = CGPoint(x: -8, y: -2000)
        let p5 = CGPoint(x: -13, y: -2012)
        XCTAssertEqual(Double(CGPoint.distanceBetween(p4, p5)), 13.0, accuracy: accuracy)

        let p6 = CGPoint.zero
        let p7 = CGPoint(x: 1, y: Darwin.sqrt(3))
        XCTAssertEqual(Double(CGPoint.distanceBetween(p6, p7)), 2.0, accuracy: accuracy)
    }

    func testCGSizeMax() {
        let zeroMax = CGSize.max(.zero, .zero)
        XCTAssertEqual(zeroMax, .zero)

        XCTAssertEqual(CGSize.max(.zero, CGSize(width: 10, height: 20)), CGSize(width: 10, height: 20))

        XCTAssertEqual(CGSize.max(CGSize(width: 10, height: 20), CGSize(width: 5, height: 30)), CGSize(width: 10, height: 30))

        XCTAssertEqual(CGSize.max(CGSize(width: -10, height: -10), CGSize(width: -5, height: 8)), CGSize(width: -5, height: 8))
    }

    func testCenterSmallerRect() {
        let smallRect1 = CGRect(x: 0, y: 0, width: 10, height: 10)
        let largeRect1 = CGRect(x: 0, y: 0, width: 20, height: 20)

        let centered1 = largeRect1.centerSmallerRect(smallRect1)
        XCTAssertEqual(centered1, CGRect(x: 5, y: 5, width: 10, height: 10))
    }

}
