//
//  PadiddleUITests.swift
//  PadiddleUITests
//
//  Created by Zev Eisenberg on 9/12/15.
//  Copyright © 2015 Zev Eisenberg. All rights reserved.
//

import XCTest

class PadiddleUITests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        XCUIDevice.sharedDevice().orientation = .Portrait
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testToolbarStaysHiddenWhileRotating() {

        let app = XCUIApplication()

        let window = app.windows.elementBoundByIndex(0)
        XCTAssert(window.exists)

        let rootView = window.childrenMatchingType(.Other).elementMatchingType(.Other, identifier: "root view")
        XCTAssert(rootView.exists)

        let toolbarViewControllerView = rootView.childrenMatchingType(.Other).elementMatchingType(.Other, identifier: "toolbar view controller view")
        XCTAssert(toolbarViewControllerView.exists)

        let toolbar = toolbarViewControllerView.childrenMatchingType(.Other).elementMatchingType(.Other, identifier: "toolbar")
        XCTAssert(toolbar.exists)

        XCTAssert(CGRectContainsRect(window.frame, toolbar.frame), "At the start, the toolbar is on screen")

        let recordButtonButton = app.buttons["record button"]
        recordButtonButton.tap()

        XCTAssertFalse(CGRectContainsRect(window.frame, toolbar.frame), "After recording begins, the toolbar is hidden")

        XCUIDevice.sharedDevice().orientation = .LandscapeRight
        XCUIDevice.sharedDevice().orientation = .Portrait

        XCTAssertFalse(CGRectContainsRect(window.frame, toolbar.frame), "After rotation, the toolbar remains hidden")

        recordButtonButton.tap()

        XCTAssertTrue(CGRectContainsRect(window.frame, toolbar.frame), "Tapping the Record button again un-hides the toolbar")
    }

}
