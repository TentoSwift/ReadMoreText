import XCTest
import UIKit
@testable import ReadMoreText

@MainActor
final class ReadMoreTextViewTests: XCTestCase {
    private let longText = String(repeating: "この自作の長い文章は、指定行数で固定した表示を検証するためのサンプルです。", count: 10)

    private func view(width: CGFloat = 300) -> ReadMoreTextView {
        let v = ReadMoreTextView(text: longText)
        v.adjustsFontForContentSizeCategory = false
        v.preferredMaxLayoutWidth = width
        return v
    }

    private func fitting(_ parent: UIView, width: CGFloat) -> CGSize {
        parent.systemLayoutSizeFitting(CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
    }

    func testInitialZeroFrameParentFittingWithKnownWidth() {
        let parent = UIView()
        let child = view()
        child.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 20),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -20),
            child.topAnchor.constraint(equalTo: parent.topAnchor, constant: 10),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -10)
        ])
        XCTAssertEqual(child.bounds.width, 0)
        XCTAssertEqual(fitting(parent, width: 340).height, child.sizeThatFits(CGSize(width: 300, height: 10000)).height + 20, accuracy: 0.5)
    }

    func testStackFirstFittingAndWidthChange() {
        let child = view()
        let stack = UIStackView(arrangedSubviews: [child])
        stack.axis = .vertical
        let first = fitting(stack, width: 300)
        XCTAssertGreaterThan(first.height, 0)
        child.preferredMaxLayoutWidth = 100
        let next = fitting(stack, width: 100)
        XCTAssertEqual(next.height, child.sizeThatFits(CGSize(width: 100, height: 10000)).height, accuracy: 0.5)
        stack.frame = CGRect(origin: .zero, size: next)
        stack.layoutIfNeeded()
        XCTAssertEqual(child.bounds.width, 100, accuracy: 0.5)
    }

    func testTapOnlyNotifiesAndPreservesTextLinesAndHeight() {
        let child = view()
        child.frame = CGRect(origin: .zero, size: child.sizeThatFits(CGSize(width: 300, height: 10000)))
        child.layoutIfNeeded()
        let renderer = child.subviews.compactMap { $0 as? ReadMoreLabelView }.first!
        renderer.layoutIfNeeded()
        var taps = 0
        child.onMoreTap = { taps += 1 }
        let before = child.intrinsicContentSize
        renderer.button.sendActions(for: .touchUpInside)
        child.layoutIfNeeded()
        XCTAssertEqual(taps, 1)
        XCTAssertEqual(child.text, longText)
        XCTAssertEqual(child.lineLimit, 2)
        XCTAssertEqual(renderer.label.numberOfLines, 2)
        XCTAssertEqual(child.intrinsicContentSize, before)
    }

    func testLongShortReplacementAndLineLimit() {
        let child = view()
        let longHeight = child.intrinsicContentSize.height
        child.text = "短文"
        XCTAssertLessThan(child.intrinsicContentSize.height, longHeight)
        child.text = longText
        child.lineLimit = 3
        XCTAssertGreaterThan(child.intrinsicContentSize.height, longHeight)
    }

    func testDirectFittingAndRequiredHeight() {
        let child = view()
        let target = CGSize(width: 180, height: 42)
        XCTAssertEqual(child.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .required), target)
        XCTAssertEqual(child.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel).height,
            child.sizeThatFits(CGSize(width: 180, height: 10000)).height)
    }

    func testVerticalPrioritiesAllowEncapsulatedHeight() {
        let child = view()
        XCTAssertLessThan(child.contentHuggingPriority(for: .vertical), .required)
        XCTAssertLessThan(child.contentCompressionResistancePriority(for: .vertical), .required)
        child.translatesAutoresizingMaskIntoConstraints = false
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 1))
        parent.addSubview(child)
        NSLayoutConstraint.activate([child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            child.topAnchor.constraint(equalTo: parent.topAnchor), child.bottomAnchor.constraint(equalTo: parent.bottomAnchor)])
        parent.layoutIfNeeded()
        XCTAssertEqual(child.bounds.height, 1, accuracy: 0.1)
    }

    func testDynamicTypeTraitChangesHeight() {
        let child = view()
        child.adjustsFontForContentSizeCategory = true
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let host = UIViewController()
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.addSubview(child)
        if #available(iOS 17.0, *) {
            child.traitOverrides.preferredContentSizeCategory = .large
            child.updateTraitsIfNeeded()
            child.traitCollectionDidChange(nil)
            let normal = child.intrinsicContentSize.height
            child.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
            child.updateTraitsIfNeeded()
            child.traitCollectionDidChange(nil)
            XCTAssertEqual(child.traitCollection.preferredContentSizeCategory, .accessibilityExtraExtraExtraLarge)
            XCTAssertGreaterThan(child.intrinsicContentSize.height, normal)
        } else {
            let normal = child.intrinsicContentSize.height
            child.font = .systemFont(ofSize: 53)
            XCTAssertGreaterThan(child.intrinsicContentSize.height, normal)
        }
    }
}
