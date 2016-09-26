//
//  ViewTests.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 6/26/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import XCTest

class ViewTests: XCTestCase {

    func testAccessibilityIdentifiers() {
        let view = UIView(axId: "foobar")
        XCTAssertEqual(view.accessibilityIdentifier, "foobar")

        let button = UIButton(type: .system, axId: "foobar")
        XCTAssertEqual(button.accessibilityIdentifier, "foobar")
    }

}
