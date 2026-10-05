# ReadMoreText — UIKit

指定行数を超えた場合だけ、最終行の末尾をフェードし、太字の「さらに表示」を重ねる `ReadMoreTextView: UIView` です。**タップは `onMoreTap` を呼ぶだけです。本文・行数・高さは変わりません。** 詳細画面への遷移などはホストアプリが決めます。

## 導入

iOS 16以上、Swift 5.9以上。外部依存・SwiftUI依存なし。
Xcodeの Add Package Dependencies → Add Local で、この `Package.swift` があるフォルダを指定し、`ReadMoreText` productをアプリへ追加してください。

```swift
import UIKit
import ReadMoreText

let descriptionView = ReadMoreTextView(text: "長い紹介文…", lineLimit: 2)
descriptionView.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(descriptionView)
NSLayoutConstraint.activate([
    descriptionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
    descriptionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
    descriptionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
])
descriptionView.onMoreTap = { [weak self] in
    self?.showDetails()
}
```

`showDetails()` はホストアプリ側で実装する処理の例です。

## Auto Layout・初回self-sizingの契約

高さを固定せず、幅を制約してください。レイアウト後は `bounds.width` からintrinsic heightを更新します。

**ゼロframeの子を含む親UIView / UIStackView / セルを、layout前に `systemLayoutSizeFitting` する場合、`preferredMaxLayoutWidth` に子の実際の本文幅を先に設定する必要があります。** 親のfitting処理は子の `systemLayoutSizeFitting` overrideを呼びません。幅が未確定の初回intrinsic heightはありません。親の四辺へ固定するだけで初回セル計測が保証されるAPIではありません。

```swift
// 親幅340pt、左右padding各20ptの例
 descriptionView.preferredMaxLayoutWidth = 340 - 40
 let size = container.systemLayoutSizeFitting(
    CGSize(width: 340, height: 0),
    withHorizontalFittingPriority: .required,
    verticalFittingPriority: .fittingSizeLevel
 )
```

回転・幅変更・セル再計測では、この幅も更新してください。常時 `preferredMaxLayoutWidth > 0` の場合、その値をintrinsic heightの計測に優先します。親の `layoutSubviews`、セルの計測処理、またはVCの `viewWillLayoutSubviews` で設定できます。0へ戻すと現在のbounds幅を使用します。

ビュー自身の `sizeThatFits` と horizontal `.required` の `systemLayoutSizeFitting` は、渡された幅で直接計測できます。vertical `.required` は指定高さを尊重します。

縦のhugging / compression resistanceは `.defaultHigh` (750)です。UITableViewの一時的なrequired encapsulated heightと競合しないため、高さを外部から小さく固定すると内容は収まりません。自動高さで使用してください。`rowHeight = .automaticDimension` を用い、幅・文字サイズ・本文変更に応じてホスト側で `performBatchUpdates(nil)` 等により再計測します。タップだけで高さ更新は不要です。

## API

| API | 意味 |
| --- | --- |
| `text` | String本文。途中で切り取りません |
| `lineLimit` | 正整数。初期値2 |
| `onMoreTap: (() -> Void)?` | ボタンまたは有効化した本文のタップ通知。自動展開なし |
| `allowsTextTap` | 初期false（ボタンのみ）。trueで行数超過時の本文タップも通知 |
| `font`, `buttonFont` | 未スケーリングのUIFont。初期17pt / 太字17pt |
| `textStyle` | Dynamic Type基準。初期 `.body` |
| `adjustsFontForContentSizeCategory` | 初期true |
| `textColor`, `buttonColor` | 本文・ボタンを別々に設定。初期 `.secondaryLabel` / `.label`。Dynamic UIColor対応 |
| `textBrightness`, `buttonBrightness` | 本文・ボタンのHSV明度倍率。0〜2、初期1 |
| `lineSpacing`, `fadeWidth` | 初期3pt / 28pt。負数は0扱い |
| `moreTitle` | nilで日本語/英語のパッケージローカライズ |
| `preferredMaxLayoutWidth` | 初回self-sizingの本文幅。初期0 |

白い文字と太字ボタンの見た目には次の設定を使います。

```swift
descriptionView.textColor = UIColor.white.withAlphaComponent(0.72)
descriptionView.buttonColor = .white
descriptionView.moreTitle = "さらに表示"
descriptionView.lineSpacing = 4
```

## 色・明るさ・本文タップ

```swift
// 本文とボタンは独立設定。Dynamic UIColorもそのまま使用できます。
descriptionView.textColor = .secondaryLabel
descriptionView.buttonColor = .label
descriptionView.textBrightness = 0.7
descriptionView.buttonBrightness = 1.2
descriptionView.allowsTextTap = true
```

`textBrightness` / `buttonBrightness` は**文字の色のHSV明度（V）への倍率**です。画面の輝度や `UIScreen.brightness` は変更しません。0で黒、1で元の色、2で元の明度の2倍（Vの最大値1で飽和）になります。白や黒など元の明度によっては1より大きくしても変化しません。値は0〜2にclampし、NaN・無限大は1に戻します。

色相・彩度・alphaは保ちます。alphaを小さくすると背景が透けますが、brightnessは透明度を変えず文字色そのものを暗く/明るくします。設定変更は直ちに描画用色へ反映し、本文・行数・高さ・超過判定は変えません。Dynamic UIColorは現在のtraitで解決した後に明度を調整するためLight/Darkの色分けが維持されます。HSV値を取得できないパターン色はそのまま使用します。

`allowsTextTap = false`（初期値）は「さらに表示」ボタンだけが通知します。trueなら表示中の本文ラベル領域のタップも同じ `onMoreTap` を呼びます。**短文で行数超過がない場合、本文タップは通知しません。** 親の余白やカード全体は対象外です。ボタンに本文用gestureを重ねず、1回のタップで通知が二重にならない構成です。本文のtap recognizerはpanを認識しないため、UIScrollViewでドラッグするとスクロールし通知しません。

VoiceOverは本文をstatic textとして全文読み上げ可能なままにし、本文タップが有効で行数超過時のみ「さらに表示」のcustom actionも提供します。独立ボタンからも操作できます。custom actionの実行はXCTestで確認済みですが、VoiceOverを起動した実操作は未実施です。

アルファマスクなので画像・グラデーション背景も透過します。UILabelに同じAttributedTextを渡し、全文と指定行数の `textRect` 高さを比較して超過を判定します。文字数の推測ではありません。マスク上段は不透明のまま、最後の行だけフェードします。

狭い幅・大きな文字・長い翻訳でボタンが最終行をほぼ覆う場合は、読みやすさのためボタンを下段へ移します。この場合は指定行数の本文＋ボタン行の高さになります。通常サイズでは最終行末尾へ重なります。

RTLではボタンとフェード位置が反転します。VoiceOverは全文を読む本文と独立ボタンを公開します。VoiceOverでの実際の操作確認は未実施です。ホストアプリで日本語を有効にするか `moreTitle` を明示してください。Markdown・リンク操作・選択・任意AttributedStringは対象外です。

## デモと実行

`Demo/ReadMoreDemo.xcodeproj` を開き、ReadMoreDemoスキームとiOS Simulatorを選んでRunしてください。幅、長短文、文字サイズ、画像背景、本文/ボタンの色・明るさ、本文タップ有効/無効、Light/Darkの操作があります。文字サイズボタンはiOS17以上で実際のcontent size categoryを切り替え、iOS16ではフォントサイズを切り替えます。通知はステータスラベルへ表示します。`Examples/DemoViewController.swift` は既存アプリへコピーする簡易サンプルです。

デモprojectは `Demo/project.yml` からXcodeGenで再生成できます。付属xcodeprojがあるためXcodeGenは実行に必須ではありません。

```sh
# パッケージフォルダで。端末名は利用可能なSimulatorに置換
xcodebuild test -scheme ReadMoreText \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test -project Demo/ReadMoreDemo.xcodeproj -scheme ReadMoreDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

デモはSimulator検証用に署名を無効化しています。ユーザーの署名・証明書・アカウントは変更していません。

## 実施済み検証

2026-10-05、Mac、Xcode 26.3 (17C519)、iPhone 17 Pro / iOS 26.2 Simulator。

- Apple SDKでパッケージとデモのコンパイル成功
- XCTest 24件成功。12件の計測/描画、7件の公開UIView、3件の色/明度、2件の本文タップ/アクセシビリティテスト
- 指定行数内/超過、日本語、明示改行、英語1行、絵文字、RTL、狭幅、ゼロ幅、マスク消去
- 公開UIViewの初回親self-sizing（既知幅あり）、UIStackView初回/幅変更、長短文・行数差し替え、required高さの尊重、縦優先度、Dynamic Type、タップ後の本文/行数/高さ維持
- Simulator UIテスト3件で通常・タップ・画像背景・幅変更・Dynamic Type・短文・長文復帰・回転、色/明度のLight/Dark切替、本文タップ切替と二重通知防止、UIScrollViewでのtap/panを操作

実機、iOS16上の実行、VoiceOver実操作、本番UITableView/UICollectionView画面での統合テストは未実施です。セル制約の検証はUIViewを使ったencapsulated height相当のrequired拘束までです。

## ライセンス

[MIT License](LICENSE) — Copyright (c) 2026 TentoSwift.
