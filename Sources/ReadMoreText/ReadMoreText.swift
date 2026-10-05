import UIKit

/// A native UIKit view that adds an inline “Show more” action only when needed.
/// Constrain its width (or set `preferredMaxLayoutWidth`) and let its intrinsic
/// height follow the fixed line limit. Taps only notify the host application.
public final class ReadMoreTextView: UIView {
    public var text: String = "" {
        didSet {
            refresh()
        }
    }
    public var lineLimit: Int = 2 {
        didSet {
            precondition(lineLimit > 0, "lineLimit must be positive")
            refresh()
        }
    }
    /// Unscaled font: Dynamic Type is applied by the component.
    public var font: UIFont = .systemFont(ofSize: 17) { didSet { refresh() } }
    public var buttonFont: UIFont = .boldSystemFont(ofSize: 17) { didSet { refresh() } }
    public var textStyle: UIFont.TextStyle = .body { didSet { refresh() } }
    public var adjustsFontForContentSizeCategory = true { didSet { refresh() } }
    public var textColor: UIColor = .secondaryLabel { didSet { refresh() } }
    public var buttonColor: UIColor = .label { didSet { refresh() } }
    /// Multiplies the resolved color's HSV brightness (V), preserving hue,
    /// saturation and alpha. 0 is black, 1 is unchanged, 2 is up to twice as
    /// bright (V saturates at 1). Values clamp to 0...2; nonfinite values use 1.
    /// This changes text color, never screen brightness.
    public var textBrightness: CGFloat = 1 {
        didSet { textBrightness = Self.normalizedBrightness(textBrightness); refresh() }
    }
    /// Same brightness multiplier as textBrightness, applied only to the button.
    public var buttonBrightness: CGFloat = 1 {
        didSet { buttonBrightness = Self.normalizedBrightness(buttonBrightness); refresh() }
    }
    /// When true, tapping the body also calls onMoreTap, but only when the text
    /// exceeds lineLimit. Default false: only the Show more button responds.
    public var allowsTextTap = false { didSet { refresh() } }
    public var lineSpacing: CGFloat = 3 { didSet { refresh() } }
    public var fadeWidth: CGFloat = 28 { didSet { refresh() } }
    /// Nil uses the package's Japanese/English localization.
    public var moreTitle: String? { didSet { refresh() } }
    /// Required for parent/stack/cell fitting before the first layout pass.
    /// Keep this equal to the actual text width whenever the parent width changes.
    public var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet { invalidateIntrinsicContentSize(); setNeedsLayout() }
    }
    /// Called when the user taps Show more. The view never expands itself.
    public var onMoreTap: (() -> Void)?

    private let content = ReadMoreLabelView()
    private var previousWidth: CGFloat = -1

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public convenience init(text: String, lineLimit: Int = 2) {
        self.init(frame: .zero)
        precondition(lineLimit > 0, "lineLimit must be positive")
        self.lineLimit = lineLimit
        self.text = text
        refresh()
    }

    private func setup() {
        backgroundColor = .clear
        addSubview(content)
        isAccessibilityElement = false
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        refresh()
    }

    private func refresh() {
        let metrics = UIFontMetrics(forTextStyle: textStyle)
        let bodyFont = adjustsFontForContentSizeCategory
            ? metrics.scaledFont(for: font, compatibleWith: traitCollection) : font
        let actionFont = adjustsFontForContentSizeCategory
            ? metrics.scaledFont(for: buttonFont, compatibleWith: traitCollection) : buttonFont
        content.configure(
            text: text, lineLimit: lineLimit,
            font: bodyFont, buttonFont: actionFont,
            textColor: Self.adjustedColor(textColor, brightness: textBrightness),
            buttonColor: Self.adjustedColor(buttonColor, brightness: buttonBrightness),
            lineSpacing: max(0, lineSpacing), fadeWidth: max(0, fadeWidth),
            moreTitle: moreTitle ?? localized("show_more"),
            accessibilityHint: localized("more_hint"),
            allowsTextTap: allowsTextTap,
            rightToLeft: effectiveUserInterfaceLayoutDirection == .rightToLeft,
            toggle: { [weak self] in
                guard let self else { return }
                self.onMoreTap?()
            }
        )
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private static func normalizedBrightness(_ value: CGFloat) -> CGFloat {
        value.isFinite ? min(2, max(0, value)) : 1
    }

    private static func adjustedColor(_ color: UIColor, brightness: CGFloat) -> UIColor {
        guard brightness != 1 else { return color }
        // Resolve inside the provider, never freeze a dynamic UIColor to the
        // current Light/Dark trait. Pattern colors have no HSV value and pass through.
        return UIColor { traits in
            let resolved = color.resolvedColor(with: traits)
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var value: CGFloat = 0
            var alpha: CGFloat = 0
            guard resolved.getHue(&hue, saturation: &saturation, brightness: &value, alpha: &alpha) else {
                return resolved
            }
            return UIColor(hue: hue, saturation: saturation,
                           brightness: min(1, value * brightness), alpha: alpha)
        }
    }

    private func localized(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: nil, table: nil)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refresh()
    }

    public override var semanticContentAttribute: UISemanticContentAttribute {
        didSet { refresh() }
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        refresh()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        content.frame = bounds
        if previousWidth != bounds.width {
            previousWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    public override var intrinsicContentSize: CGSize {
        let width = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width
        guard width > 0 else {
            return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
        }
        return CGSize(width: UIView.noIntrinsicMetric,
                      height: content.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        content.sizeThatFits(size)
    }

    public override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let width = horizontalFittingPriority == .required
            ? targetSize.width
            : (preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.width)
        guard width > 0, width.isFinite else {
            return super.systemLayoutSizeFitting(targetSize,
                withHorizontalFittingPriority: horizontalFittingPriority,
                verticalFittingPriority: verticalFittingPriority)
        }
        let fit = content.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: width, height: verticalFittingPriority == .required ? targetSize.height : fit.height)
    }
}
