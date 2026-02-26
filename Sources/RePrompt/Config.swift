import Foundation

enum Config {
    private static let defaultThreshold: TimeInterval = 60
    private static let thresholdKey = "idleThreshold"

    /// アイドル閾値（秒）。UserDefaults に保存される
    static var idleThreshold: TimeInterval {
        get {
            let saved = UserDefaults.standard.double(forKey: thresholdKey)
            return saved > 0 ? saved : defaultThreshold
        }
        set {
            UserDefaults.standard.set(newValue, forKey: thresholdKey)
        }
    }

    /// ポーリング間隔（秒）
    static let pollingInterval: TimeInterval = 1.0

    /// ウィンドウサイズ
    static let windowWidth: CGFloat = 800
    static let windowHeight: CGFloat = 450

    /// メディアファイル格納ディレクトリ
    static var mediaDirectoryURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("RePrompt/Media")
    }

    /// オーバーレイ表示メッセージ
    static let overlayMessage = "何やってるんですか仕事してください"

    static let videoExtensions: Set<String> = ["mp4", "mov", "m4v"]
    static let imageExtensions: Set<String> = ["jpg", "jpeg", "png"]
    static let audioExtensions: Set<String> = ["mp3", "m4a", "wav", "aac"]
}
