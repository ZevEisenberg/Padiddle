//
//  Screenshots.swift
//  Padiddle
//
//  Created by Zev Eisenberg on 4/8/16.
//  Copyright © 2016 Zev Eisenberg. All rights reserved.
//

import XCTest

class Screenshots: XCTestCase {

    lazy var iPhone = UIDevice.current.userInterfaceIdiom == .phone

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.

        let app = XCUIApplication()
        setupSnapshot(app: app)
        app.launch()

        XCUIDevice.shared().orientation = .portrait
    }

    func testTakeScreenshots() {

        snapshot(name: "1")

        let app = XCUIApplication()

        let helpButton = app.buttons["help button"]
        XCTAssertTrue(helpButton.exists)
        helpButton.tap()

        snapshot(name: "2")

        if iPhone {
            let navBar = app.navigationBars["about padiddle"]
            XCTAssertTrue(navBar.exists)
            let doneButton = navBar.buttons["done button"]
            XCTAssertTrue(doneButton.exists)
            doneButton.tap()
        } else {
            let dismissRegion = XCUIApplication().otherElements["PopoverDismissRegion"]
            XCTAssertTrue(dismissRegion.exists)
            dismissRegion.tap()
        }

        app.buttons["color button"].tap()

        snapshot(name: "3")
    }

}
