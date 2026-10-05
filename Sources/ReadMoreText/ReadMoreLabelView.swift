import UIKit

/// UIKit measures and renders the same attributed text without character slicing.
final class ReadMoreLabelView: UIView {
    let label = UILabel()
    let button = UIButton(type: .system)
    private var limit = 2
    private var rightToLeft = false
    private var fadeWidth: CGFloat = 28
    private var toggle: (() -> Void)?
    private var allowsTextTap = false
    private var moreTitle = ""
    private let buttonMeasurer = UILabel()

    struct Measurement {
        let textHeight: CGFloat
        let buttonSize: CGSize
        let overflows: Bool
        let showsButton: Bool
        let separateButton: Bool
        var height: CGFloat {
            textHeight + (showsButton && separateButton ? 4 + max(44, buttonSize.height) : 0)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        label.backgroundColor = .clear
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        label.lineBreakMode = .byTruncatingTail
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .trailing
        button.contentVerticalAlignment = .bottom
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.addAction(UIAction { [weak self] _ in self?.toggle?() }, for: .touchUpInside)
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTextTap)))
        addSubview(label)
        addSubview(button)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    func configure(
        text: String, lineLimit: Int,
        font: UIFont, buttonFont: UIFont,
        textColor: UIColor, buttonColor: UIColor,
        lineSpacing: CGFloat, fadeWidth: CGFloat,
        moreTitle: String, accessibilityHint: String,
        allowsTextTap: Bool = false,
        rightToLeft: Bool, toggle: @escaping () -> Void
    ) {
        self.limit = max(1, lineLimit)
        self.rightToLeft = rightToLeft
        self.fadeWidth = max(0, fadeWidth)
        self.toggle = toggle
        self.allowsTextTap = allowsTextTap
        self.moreTitle = moreTitle
        semanticContentAttribute = rightToLeft ? .forceRightToLeft : .forceLeftToRight
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = max(0, lineSpacing)
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .natural
        paragraph.baseWritingDirection = rightToLeft ? .rightToLeft : .leftToRight
        label.font = font
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: textColor, .paragraphStyle: paragraph
        ])
        label.numberOfLines = limit
        // VoiceOver can read the complete content without needing to expand it.
        label.accessibilityLabel = text
        button.titleLabel?.font = buttonFont
        buttonMeasurer.font = buttonFont
        buttonMeasurer.numberOfLines = 0
        buttonMeasurer.lineBreakMode = .byWordWrapping
        buttonMeasurer.text = moreTitle
        button.setTitle(moreTitle, for: .normal)
        button.setTitleColor(buttonColor, for: .normal)
        button.accessibilityHint = accessibilityHint
        button.contentHorizontalAlignment = rightToLeft ? .left : .right
        updateTextInteraction(overflows: measurement(width: bounds.width).overflows)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    func measurement(width: CGFloat) -> Measurement {
        guard width > 0, width.isFinite else {
            return Measurement(textHeight: 0, buttonSize: .zero, overflows: false,
                               showsButton: false, separateButton: false)
        }
        let bounds = CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude)
        let lines = label.numberOfLines
        label.numberOfLines = 0
        let full = label.textRect(forBounds: bounds, limitedToNumberOfLines: 0).height
        label.numberOfLines = lines
        let limited = label.textRect(forBounds: bounds, limitedToNumberOfLines: limit).height
        let overflows = full > limited + 0.5
        let showsButton = overflows
        let naturalButton = buttonMeasurer.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
        let buttonSize = buttonMeasurer.sizeThatFits(
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        )
        // At large accessibility sizes / narrow widths, preserve readable text
        // instead of allowing the affordance to cover nearly the entire last line.
        let separate = naturalButton.width + fadeWidth + label.font.lineHeight > width
            || buttonSize.height > label.font.lineHeight + 1
        return Measurement(
            textHeight: ceil(limited),
            buttonSize: CGSize(width: min(width, ceil(buttonSize.width)), height: ceil(buttonSize.height)),
            overflows: overflows, showsButton: showsButton, separateButton: separate
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = size.width.isFinite ? max(0, size.width) : 0
        return CGSize(width: width, height: ceil(measurement(width: width).height))
    }

    override var intrinsicContentSize: CGSize {
        guard bounds.width > 0 else { return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric) }
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(measurement(width: bounds.width).height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let m = measurement(width: bounds.width)
        updateTextInteraction(overflows: m.overflows)
        label.frame = CGRect(x: 0, y: 0, width: bounds.width, height: m.textHeight)
        button.isHidden = !m.showsButton
        label.layer.mask = nil
        accessibilityElements = m.showsButton ? [label, button] : [label]
        guard m.showsButton else { return }
        let x = rightToLeft ? 0 : bounds.width - m.buttonSize.width
        if m.separateButton {
            button.frame = CGRect(x: x, y: m.textHeight + 4,
                                  width: m.buttonSize.width, height: max(44, m.buttonSize.height))
            return
        }
        button.frame = CGRect(x: x, y: max(0, m.textHeight - max(44, m.buttonSize.height)),
                              width: m.buttonSize.width, height: min(m.textHeight, max(44, m.buttonSize.height)))
        applyFade(buttonWidth: m.buttonSize.width)
    }

    private func updateTextInteraction(overflows: Bool) {
        let enabled = allowsTextTap && overflows
        label.isUserInteractionEnabled = enabled
        // Keep the complete text readable as static text. VoiceOver users get
        // an explicit custom action in addition to the independent button.
        label.accessibilityCustomActions = enabled ? [UIAccessibilityCustomAction(name: moreTitle) { [weak self] _ in
            self?.performTextAction() ?? false
        }] : nil
    }

    @objc func handleTextTap() { _ = performTextAction() }

    private func performTextAction() -> Bool {
        guard allowsTextTap, measurement(width: bounds.width).overflows else { return false }
        toggle?()
        return true
    }

    private func applyFade(buttonWidth: CGFloat) {
        let width = label.bounds.width
        let height = label.bounds.height
        let priorHeight: CGFloat = limit > 1
            ? label.textRect(forBounds: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude),
                             limitedToNumberOfLines: limit - 1).height : 0
        let bandHeight = min(height, max(0, height - ceil(priorHeight)))
        let bandY = height - bandHeight
        let mask = CALayer()
        mask.frame = label.bounds
        // Keep earlier lines fully visible, even directly above the button.
        let upper = CALayer()
        upper.frame = CGRect(x: 0, y: 0, width: width, height: bandY)
        upper.backgroundColor = UIColor.black.cgColor
        mask.addSublayer(upper)
        let covered = min(width, buttonWidth + 4)
        let fade = min(fadeWidth, max(0, width - covered))
        let solidWidth = max(0, width - covered - fade)
        let solid = CALayer()
        solid.frame = CGRect(x: rightToLeft ? covered + fade : 0, y: bandY,
                             width: solidWidth, height: bandHeight)
        solid.backgroundColor = UIColor.black.cgColor
        mask.addSublayer(solid)
        if fade > 0 {
            let gradient = CAGradientLayer()
            gradient.frame = CGRect(x: rightToLeft ? covered : solidWidth, y: bandY,
                                    width: fade, height: bandHeight)
            gradient.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
            gradient.startPoint = CGPoint(x: rightToLeft ? 1 : 0, y: 0.5)
            gradient.endPoint = CGPoint(x: rightToLeft ? 0 : 1, y: 0.5)
            mask.addSublayer(gradient)
        }
        // A transparent alpha mask works over arbitrary backgrounds, including images.
        label.layer.mask = mask
    }

}
