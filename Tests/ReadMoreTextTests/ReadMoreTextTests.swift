import XCTest
import UIKit
@testable import ReadMoreText

@MainActor
final class ReadMoreTextTests: XCTestCase {
    private let japanese = String(repeating: "日本語の長い紹介文です。指定行数を超えたときにさらに表示します。", count: 12)

    private func makeView(
        _ text: String, lines: Int = 2, size: CGFloat = 17,
        rtl: Bool = false, onTap: @escaping () -> Void = {}
    ) -> ReadMoreLabelView {
        let view = ReadMoreLabelView()
        view.configure(
            text: text, lineLimit: lines,
            font: .systemFont(ofSize: size), buttonFont: .boldSystemFont(ofSize: size),
            textColor: .label, buttonColor: .label, lineSpacing: 3, fadeWidth: 28,
            moreTitle: "さらに表示", accessibilityHint: "全文を表示します",
            rightToLeft: rtl, toggle: onTap
        )
        return view
    }

    private func layout(_ view: ReadMoreLabelView, width: CGFloat) {
        view.frame = CGRect(origin: .zero, size: view.sizeThatFits(CGSize(width: width, height: 10_000)))
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func testEmptyAndShortTextDoNotShowButton() {
        for text in ["", "短い文章", "One line"] {
            let m = makeView(text).measurement(width: 320)
            XCTAssertFalse(m.overflows)
            XCTAssertFalse(m.showsButton)
        }
    }

    func testExactlyTwoExplicitLinesDoNotOverflow() {
        XCTAssertFalse(makeView("一行目\n二行目").measurement(width: 320).overflows)
    }

    func testThreeExplicitLinesOverflowTwoLineLimit() {
        XCTAssertTrue(makeView("一行目\n二行目\n三行目").measurement(width: 320).overflows)
    }

    func testJapaneseWrappingShowsInlineButton() {
        let m = makeView(japanese).measurement(width: 360)
        XCTAssertTrue(m.overflows)
        XCTAssertTrue(m.showsButton)
        XCTAssertFalse(m.separateButton)
    }

    func testWidthChangesRecomputeOverflow() {
        let view = makeView("This sentence fits at a wide width but wraps narrowly.", lines: 1)
        XCTAssertTrue(view.measurement(width: 90).overflows)
        XCTAssertFalse(view.measurement(width: 2_000).overflows)
    }

    func testLargerFontChangesMeasurement() {
        let normal = makeView(japanese).measurement(width: 320)
        let large = makeView(japanese, size: 53).measurement(width: 320)
        XCTAssertGreaterThan(large.textHeight, normal.textHeight)
        XCTAssertTrue(large.separateButton)
    }

    func testNarrowWidthKeepsButtonOutsideText() {
        let m = makeView(japanese).measurement(width: 65)
        XCTAssertTrue(m.separateButton)
        XCTAssertGreaterThan(m.height, m.textHeight)
    }

    func testInlineMaskIsRemovedWhenReconfiguredWithShortText() {
        let view = makeView(japanese)
        layout(view, width: 360)
        XCTAssertNotNil(view.label.layer.mask)
        view.configure(text: "短文", lineLimit: 2,
                       font: .systemFont(ofSize: 17), buttonFont: .boldSystemFont(ofSize: 17),
                       textColor: .label, buttonColor: .label, lineSpacing: 3, fadeWidth: 28,
                       moreTitle: "さらに表示", accessibilityHint: "",
                       rightToLeft: false, toggle: {})
        layout(view, width: 360)
        XCTAssertNil(view.label.layer.mask)
        XCTAssertTrue(view.button.isHidden)
    }

    func testTapCallsBindingActionAndAccessibilityIncludesButton() {
        var taps = 0
        let view = makeView(japanese, onTap: { taps += 1 })
        layout(view, width: 360)
        view.button.sendActions(for: .touchUpInside)
        XCTAssertEqual(taps, 1)
        XCTAssertEqual(view.accessibilityElements?.count, 2)
        XCTAssertEqual(view.label.accessibilityLabel, japanese)
    }

    func testRightToLeftButtonIsAtLeadingVisualEdge() {
        let view = makeView(String(repeating: "هذه فقرة عربية طويلة للاختبار ", count: 20), rtl: true)
        layout(view, width: 360)
        XCTAssertEqual(view.button.frame.minX, 0, accuracy: 0.1)
        XCTAssertNotNil(view.label.layer.mask)
    }

    func testEmojiAndLongTokensAreNotManuallySliced() {
        let text = String(repeating: "👨‍👩‍👧‍👦🏳️‍🌈e\u{301}https://example.com/longpath", count: 15)
        let view = makeView(text)
        XCTAssertEqual(view.label.attributedText?.string, text)
        XCTAssertTrue(view.measurement(width: 240).overflows)
    }

    func testZeroWidthIsSafe() {
        let m = makeView(japanese).measurement(width: 0)
        XCTAssertEqual(m.height, 0)
        XCTAssertFalse(m.showsButton)
    }
}
