import XCTest
import UIKit
@testable import ReadMoreText

@MainActor
final class ReadMoreColorTests: XCTestCase {
    private func renderer(_ v: ReadMoreTextView) -> ReadMoreLabelView {
        v.subviews.compactMap { $0 as? ReadMoreLabelView }.first!
    }

    private func bodyColor(_ v: ReadMoreTextView) -> UIColor {
        renderer(v).label.attributedText!.attribute(.foregroundColor, at: 0, effectiveRange: nil) as! UIColor
    }

    private func hsv(_ color: UIColor, style: UIUserInterfaceStyle = .light) -> [CGFloat] {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            .getHue(&h, saturation: &s, brightness: &b, alpha: &a))
        return [h, s, b, a]
    }

    func testIndependentColorBrightnessUpdatesImmediatelyWithoutLayoutChanges() {
        let v = ReadMoreTextView(text: String(repeating: "長い紹介文の表示テストです。", count: 15))
        v.preferredMaxLayoutWidth = 320
        let size = v.intrinsicContentSize
        let before = renderer(v).measurement(width: 320)
        v.textColor = UIColor(hue: 0.2, saturation: 0.4, brightness: 0.6, alpha: 0.7)
        v.buttonColor = UIColor(hue: 0.8, saturation: 0.5, brightness: 0.4, alpha: 0.9)
        v.textBrightness = 0.5
        v.buttonBrightness = 1.5
        XCTAssertEqual(hsv(bodyColor(v))[2], 0.3, accuracy: 0.001)
        XCTAssertEqual(hsv(bodyColor(v))[3], 0.7, accuracy: 0.001)
        XCTAssertEqual(hsv(renderer(v).button.titleColor(for: .normal)!)[2], 0.6, accuracy: 0.001)
        XCTAssertEqual(hsv(renderer(v).button.titleColor(for: .normal)!)[3], 0.9, accuracy: 0.001)
        XCTAssertEqual(v.intrinsicContentSize, size)
        let after = renderer(v).measurement(width: 320)
        XCTAssertEqual(after.overflows, before.overflows)
        XCTAssertEqual(after.separateButton, before.separateButton)
        XCTAssertEqual(v.lineLimit, 2)
        v.textBrightness = 1
        XCTAssertEqual(hsv(bodyColor(v))[2], 0.6, accuracy: 0.001)
    }

    func testDynamicColorResolvesSeparatelyForLightAndDarkAndKeepsHueAlpha() {
        let color = UIColor { traits in
            UIColor(hue: 0.3, saturation: 0.4,
                    brightness: traits.userInterfaceStyle == .dark ? 0.8 : 0.4, alpha: 0.6)
        }
        let v = ReadMoreTextView(text: "text")
        v.textColor = color
        v.buttonColor = color
        v.textBrightness = 0.5
        v.buttonBrightness = 0.5
        for adjusted in [bodyColor(v), renderer(v).button.titleColor(for: .normal)!] {
            let light = hsv(adjusted)
            let dark = hsv(adjusted, style: .dark)
            XCTAssertEqual(light[2], 0.2, accuracy: 0.001)
            XCTAssertEqual(dark[2], 0.4, accuracy: 0.001)
            XCTAssertEqual(dark[0], 0.3, accuracy: 0.001)
            XCTAssertEqual(dark[1], 0.4, accuracy: 0.001)
            XCTAssertEqual(dark[3], 0.6, accuracy: 0.001)
        }
    }

    func testRangeClampingAndBrightnessSaturation() {
        let v = ReadMoreTextView(text: "text")
        v.textColor = UIColor(white: 0.8, alpha: 0.4)
        v.textBrightness = -1
        XCTAssertEqual(v.textBrightness, 0)
        XCTAssertEqual(hsv(bodyColor(v))[2], 0, accuracy: 0.001)
        v.textBrightness = 10
        XCTAssertEqual(v.textBrightness, 2)
        XCTAssertEqual(hsv(bodyColor(v))[2], 1, accuracy: 0.001)
        XCTAssertEqual(hsv(bodyColor(v))[3], 0.4, accuracy: 0.001)
        v.textBrightness = .nan
        v.buttonBrightness = .infinity
        XCTAssertEqual(v.textBrightness, 1)
        XCTAssertEqual(v.buttonBrightness, 1)
        v.buttonBrightness = -5
        XCTAssertEqual(v.buttonBrightness, 0)
    }
}
