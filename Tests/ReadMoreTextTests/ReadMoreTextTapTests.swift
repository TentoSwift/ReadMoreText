import XCTest
import UIKit
@testable import ReadMoreText

@MainActor
final class ReadMoreTextTapTests: XCTestCase {
    func testTextTapConfigurationChangesImmediatelyAndShortTextDoesNotNotify() {
        let v = ReadMoreTextView(text: String(repeating: "長い文章を指定行数で表示します。", count: 10))
        let size = v.sizeThatFits(CGSize(width: 320, height: 10000))
        v.frame = CGRect(origin: .zero, size: size)
        v.layoutIfNeeded()
        let content = v.subviews.compactMap { $0 as? ReadMoreLabelView }.first!
        content.layoutIfNeeded()
        var calls = 0
        v.onMoreTap = { calls += 1 }
        XCTAssertFalse(v.allowsTextTap)
        XCTAssertFalse(content.label.isUserInteractionEnabled)
        content.handleTextTap()
        XCTAssertEqual(calls, 0)
        v.allowsTextTap = true
        XCTAssertTrue(content.label.isUserInteractionEnabled)
        content.handleTextTap()
        XCTAssertEqual(calls, 1)
        content.button.sendActions(for: .touchUpInside)
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(v.sizeThatFits(CGSize(width: 320, height: 10000)), size)
        XCTAssertEqual(content.label.numberOfLines, 2)
        v.allowsTextTap = false
        XCTAssertFalse(content.label.isUserInteractionEnabled)
        content.handleTextTap()
        XCTAssertEqual(calls, 2)
        v.allowsTextTap = true
        v.text = "短文"
        XCTAssertFalse(content.label.isUserInteractionEnabled)
        content.handleTextTap()
        XCTAssertEqual(calls, 2)
    }

    func testVoiceOverBodyCustomActionOnlyWhenEnabledAndOverflowing() {
        let v = ReadMoreTextView(text: String(repeating: "長い文章です。", count: 40))
        v.frame = CGRect(origin: .zero, size: v.sizeThatFits(CGSize(width: 320, height: 10000)))
        v.layoutIfNeeded()
        let content = v.subviews.compactMap { $0 as? ReadMoreLabelView }.first!
        content.layoutIfNeeded()
        var calls = 0
        v.onMoreTap = { calls += 1 }
        XCTAssertNil(content.label.accessibilityCustomActions)
        v.allowsTextTap = true
        let action = content.label.accessibilityCustomActions!.first!
        XCTAssertTrue(action.actionHandler!(action))
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(content.label.accessibilityLabel, v.text)
        XCTAssertTrue(content.label.accessibilityTraits.contains(.staticText))
        XCTAssertEqual(content.accessibilityElements?.count, 2)
        v.text = "短文"
        XCTAssertNil(content.label.accessibilityCustomActions)
        XCTAssertFalse(action.actionHandler!(action))
        XCTAssertEqual(calls, 1)
    }
}
