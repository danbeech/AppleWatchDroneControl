//
//  UITestBundle.swift
//  UITestBundle
//
//  Created by Daniel Beech on 30/04/2020.
//  Copyright © 2020 Dan Beech. All rights reserved.
//

import XCTest

class UITestBundle: XCTestCase {

      //Global reference to the application to be tested
        var app: XCUIApplication!

        override func setUpWithError() throws {
            // Put setup code here. This method is called before the invocation of each test method in the class.
            super.setUp()
            // In UI tests it is usually best to stop immediately when a failure occurs.
            continueAfterFailure = false
            
            //instantiation of the application to be tested
            app = XCUIApplication()
            app.launchArguments.append("--UI-Tests--")
            // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        }

        override func tearDownWithError() throws {
            // Put teardown code here. This method is called after the invocation of each test method in the class.
        }

    //    func testExample() throws {
    //        // UI tests must launch the application that they test.
    //        let app = XCUIApplication()
    //        app.launch()
    //
    //        // Use recording to get started writing UI tests.
    //        // Use XCTAssert and related functions to verify your tests produce the correct results.
    //    }
        
        //START OF MY TESTS
        func testTakeOffButtonLoaded() {
            app.launch()
            XCTAssertTrue(app.buttons["Take Off"].exists)
        }
        func testEmergencyButtonLoaded() {
            app.launch()
            XCTAssertTrue(app.buttons["Emergency Landing"].exists)
        }
        func testTakeOffToLandLabelChangeOnTap() {
            app.launch()
            app.buttons["Take Off"].tap()
            XCTAssertTrue(app.buttons["Land"].exists)
        }
        
        //END OF MY TESTS
        
        //Generic pre-built function, not my code - Tests how long it takes to boot the application.
        func testLaunchPerformance() throws {
            if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
                // This measures how long it takes to launch your application.
                measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                    XCUIApplication().launch()
                }
            }
        }
    }
