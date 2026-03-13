//
//  NeurovaUITests.swift
//  NeurovaUITests
//
//  Created by Angel Orellana on 2/03/26.
//

import XCTest

final class NeurovaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchShowsExpectedRootExperience() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            rootIndicator(in: app).waitForExistence(timeout: 5),
            "The app should present either onboarding or the main authenticated shell after launch."
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testOnboardingOrShellExposesPrimaryNavigationElement() throws {
        let app = XCUIApplication()
        app.launch()

        if onboardingIndicator(in: app).waitForExistence(timeout: 3) {
            let continueButton = app.buttons["Continue"].firstMatch
            let continuarButton = app.buttons["Continuar"].firstMatch
            XCTAssertTrue(
                continueButton.exists || continuarButton.exists,
                "Onboarding should expose its primary action."
            )
            return
        }

        let libraryTab = app.staticTexts["Library"].firstMatch
        let bibliotecaTab = app.staticTexts["Biblioteca"].firstMatch
        XCTAssertTrue(
            libraryTab.waitForExistence(timeout: 3) || bibliotecaTab.waitForExistence(timeout: 3),
            "The authenticated shell should expose tab navigation."
        )
    }

    private func rootIndicator(in app: XCUIApplication) -> XCUIElement {
        let candidates = [
            onboardingIndicator(in: app),
            app.staticTexts["Home"].firstMatch,
            app.staticTexts["Inicio"].firstMatch
        ]

        return candidates.first { $0.exists } ?? candidates[0]
    }

    private func onboardingIndicator(in app: XCUIApplication) -> XCUIElement {
        let english = app.staticTexts["Welcome to Neurova"].firstMatch
        let spanish = app.staticTexts["Bienvenido a Neurova"].firstMatch
        return english.exists ? english : spanish
    }
}
