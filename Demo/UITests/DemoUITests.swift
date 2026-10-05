import XCTest
final class DemoUITests: XCTestCase {
    private func body(_ app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "このコンポーネント")).firstMatch
    }

    func testColorsBrightnessAndOptionalTextTap() {
        let app = XCUIApplication()
        app.launch()
        let text = body(app)
        XCTAssertTrue(text.waitForExistence(timeout: 10))
        let status = app.staticTexts["status"]
        let frame = text.frame
        let fullText = text.label
        let point = text.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.15))
        point.tap()
        XCTAssertEqual(status.value as? String, "0")
        app.buttons["textTap"].tap()
        point.tap()
        XCTAssertEqual(status.value as? String, "1")
        app.buttons["さらに表示"].tap()
        XCTAssertEqual(status.value as? String, "2")
        XCTAssertEqual(text.frame, frame)
        XCTAssertEqual(text.label, fullText)
        shot("09-body-tap")
        app.buttons["color"].tap()
        shot("10-color-light")
        app.buttons["brightness"].tap()
        XCTAssertEqual(text.frame, frame)
        shot("11-brightness-light")
        app.buttons["theme"].tap()
        XCTAssertEqual(text.frame, frame)
        shot("12-brightness-dark")
        app.buttons["brightness"].tap()
        shot("13-color-dark")
        app.buttons["textTap"].tap()
        point.tap()
        XCTAssertEqual(status.value as? String, "2")
        app.buttons["textTap"].tap()
        app.buttons["text"].tap()
        let short = app.staticTexts["短い文章です。"]
        short.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)).tap()
        XCTAssertEqual(status.value as? String, "2")
        XCTAssertFalse(app.buttons["さらに表示"].exists)
    }

    func testTextTapDoesNotPreventScrollingOrNotifyForPan() {
        let app = XCUIApplication()
        app.launchArguments = ["--scroll-test"]
        app.launch()
        let text = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "スクロール中は")).firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 10))
        let status = app.staticTexts["scrollStatus"]
        text.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.15)).tap()
        XCTAssertEqual(status.label, "通知回数: 1")
        let beforeY = text.frame.minY
        let start = text.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -200)))
        XCTAssertLessThan(text.frame.minY, beforeY)
        app.scrollViews.firstMatch.swipeDown()
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.label, "通知回数: 1")
        shot("14-scroll-tap-pan")
    }
    func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }
    func testScenarios() {
        let app = XCUIApplication()
        app.launch()
        let more = app.buttons["さらに表示"]
        XCTAssertTrue(more.waitForExistence(timeout: 10))
        shot("01-default")
        let before = more.frame
        more.tap()
        XCTAssertTrue(app.staticTexts["通知を受信しました。本文は2行のまま。"].exists)
        XCTAssertEqual(more.frame, before)
        shot("02-tap-no-expansion")
        app.buttons["background"].tap()
        shot("03-image-background")
        app.buttons["width"].tap()
        XCTAssertTrue(more.exists)
        shot("04-narrow")
        app.buttons["width"].tap()
        app.buttons["font"].tap()
        XCTAssertTrue(more.exists)
        shot("05-dynamic-type")
        app.buttons["font"].tap()
        app.buttons["text"].tap()
        XCTAssertFalse(more.exists)
        shot("06-short")
        app.buttons["text"].tap()
        XCTAssertTrue(more.exists)
        shot("07-long-restored")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(more.waitForExistence(timeout: 5))
        shot("08-landscape")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(more.waitForExistence(timeout: 5))
    }
}
