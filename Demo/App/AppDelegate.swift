import UIKit
import ReadMoreText

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ProcessInfo.processInfo.arguments.contains("--scroll-test") ? ScrollDemoController() : DemoController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

final class DemoController: UIViewController {
    let textView = ReadMoreTextView()
    let card = UIView()
    let backgroundImage = UIImageView()
    let status = UILabel()
    var narrow = false
    var short = false
    var large = false
    var widthConstraint: NSLayoutConstraint!
    var alternateColor = false
    var dim = false
    var dark = false
    var taps = 0
    let sample = "このコンポーネントは、指定した行数を超える紹介文の末尾に「さらに表示」を重ねて表示します。本文を展開することなく、タップをアプリへ通知します。色、明るさ、文字サイズ、幅に合わせて表示を調整できるUIKitのサンプルです。"

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
        let heading = UILabel()
        heading.text = "ReadMoreText — UIKit"
        heading.font = .boldSystemFont(ofSize: 22)
        heading.textColor = .white
        stack.addArrangedSubview(heading)
        card.isUserInteractionEnabled = true
        card.layer.cornerRadius = 16
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = UIColor.white.withAlphaComponent(0.72)
        textView.buttonColor = .white
        textView.moreTitle = "さらに表示"
        textView.lineSpacing = 4
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        backgroundImage.isAccessibilityElement = false
        card.addSubview(backgroundImage)
        NSLayoutConstraint.activate([backgroundImage.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            backgroundImage.topAnchor.constraint(equalTo: card.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: card.bottomAnchor)])
        card.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            textView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            textView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
        let cardHost = UIView()
        cardHost.addSubview(card)
        widthConstraint = card.widthAnchor.constraint(equalTo: cardHost.widthAnchor)
        NSLayoutConstraint.activate([widthConstraint, card.leadingAnchor.constraint(equalTo: cardHost.leadingAnchor),
            card.topAnchor.constraint(equalTo: cardHost.topAnchor), card.bottomAnchor.constraint(equalTo: cardHost.bottomAnchor)])
        stack.addArrangedSubview(cardHost)
        status.text = "タップはアプリへ通知。本文は2行のまま。"
        status.textColor = .white
        status.font = .systemFont(ofSize: 14)
        status.numberOfLines = 0
        status.accessibilityIdentifier = "status"
        status.accessibilityValue = "0"
        stack.addArrangedSubview(status)
        let controls: [(String, Selector, String)] = [
            ("幅を変更", #selector(changeWidth), "width"), ("長文 / 短文", #selector(changeText), "text"),
            ("文字サイズ", #selector(changeFont), "font"), ("画像背景", #selector(changeBackground), "background"),
            ("文字色", #selector(changeColor), "color"), ("明るさ", #selector(changeBrightness), "brightness"),
            ("本文タップ切替", #selector(changeTextTap), "textTap"), ("Light / Dark", #selector(changeTheme), "theme")
        ]
        for index in stride(from: 0, to: controls.count, by: 2) {
            let row = UIStackView()
            row.distribution = .fillEqually
            for (title, selector, id) in controls[index..<min(index + 2, controls.count)] {
                let b = UIButton(type: .system)
                b.setTitle(title, for: .normal)
                b.accessibilityIdentifier = id
                b.addTarget(self, action: selector, for: .touchUpInside)
                row.addArrangedSubview(b)
            }
            stack.addArrangedSubview(row)
        }
        textView.onMoreTap = { [weak self] in
            guard let self else { return }
            self.taps += 1
            self.status.text = "通知を受信しました。本文は2行のまま。"
            self.status.accessibilityValue = String(self.taps)
        }
        updateText()
        card.backgroundColor = UIColor(red: 0.23, green: 0.13, blue: 0.14, alpha: 1)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        textView.preferredMaxLayoutWidth = max(1, view.bounds.width - 80 - (narrow ? 120 : 0))
    }
    func updateText() { textView.text = short ? "短い文章です。" : sample }
    @objc func changeWidth() { narrow.toggle(); widthConstraint.constant = narrow ? -120 : 0; view.setNeedsLayout() }
    @objc func changeText() { short.toggle(); updateText() }
    @objc func changeColor() {
        alternateColor.toggle()
        textView.textColor = alternateColor ? UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.7, green: 0.9, blue: 1, alpha: 1)
                : UIColor(red: 1, green: 0.75, blue: 0.35, alpha: 1)
        } : UIColor.white.withAlphaComponent(0.72)
        textView.buttonColor = alternateColor ? UIColor { traits in
            traits.userInterfaceStyle == .dark ? .systemYellow : .systemMint
        } : .white
    }
    @objc func changeBrightness() {
        dim.toggle()
        textView.textBrightness = dim ? 0.55 : 1
        textView.buttonBrightness = dim ? 0.75 : 1
    }
    @objc func changeTextTap() { textView.allowsTextTap.toggle() }
    @objc func changeTheme() {
        dark.toggle()
        overrideUserInterfaceStyle = dark ? .dark : .light
    }
    @objc func changeFont() {
        large.toggle()
        if #available(iOS 17.0, *) {
            traitOverrides.preferredContentSizeCategory = large ? .accessibilityExtraExtraExtraLarge : .large
        } else {
            textView.font = .systemFont(ofSize: large ? 53 : 17)
            textView.buttonFont = .boldSystemFont(ofSize: large ? 53 : 17)
        }
        view.setNeedsLayout()
    }
    @objc func changeBackground() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600))
        backgroundImage.image = renderer.image { c in
            UIColor(red: 0.12, green: 0.24, blue: 0.26, alpha: 1).setFill()
            c.fill(CGRect(x: 0, y: 0, width: 600, height: 600))
            for i in 0..<9 {
                UIColor(red: 0.5, green: 0.27, blue: 0.14, alpha: 0.7).setFill()
                UIBezierPath(ovalIn: CGRect(x: i * 90 - 100, y: i * 45 - 80, width: 220, height: 220)).fill()
            }
        }
    }
}

// Manual-layout scroll fixture for real tap/pan arbitration.
final class ScrollDemoController: UIViewController {
    let scroll = UIScrollView()
    let textView = ReadMoreTextView()
    let status = UILabel()
    var taps = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(scroll)
        scroll.addSubview(textView)
        scroll.addSubview(status)
        textView.text = String(repeating: "スクロール中は通知せず、本文のタップだけを通知する検証文章です。", count: 8)
        textView.moreTitle = "さらに表示"
        textView.textColor = .white
        textView.buttonColor = .white
        textView.allowsTextTap = true
        textView.onMoreTap = { [weak self] in
            guard let self else { return }
            self.taps += 1
            self.status.text = "通知回数: \(self.taps)"
        }
        status.text = "通知回数: 0"
        status.textColor = .white
        status.accessibilityIdentifier = "scrollStatus"
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.frame = view.bounds.inset(by: view.safeAreaInsets)
        scroll.contentSize = CGSize(width: scroll.bounds.width, height: 2000)
        let width = scroll.bounds.width - 40
        textView.frame = CGRect(origin: CGPoint(x: 20, y: 20),
            size: textView.sizeThatFits(CGSize(width: width, height: 10000)))
        status.frame = CGRect(x: 20, y: textView.frame.maxY + 20, width: width, height: 30)
    }
}
