import AppKit
import AVFoundation
import AVKit

final class AlertWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var player: AVPlayer?
    private var audioPlayer: AVAudioPlayer?
    private var loopObserver: Any?

    /// ユーザーが手動でウィンドウを閉じたときのコールバック
    var onDismiss: (() -> Void)?

    func show() {
        let window = NSWindow(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Config.windowWidth,
                height: Config.windowHeight
            ),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.center()
        window.title = "Re:Prompt"
        window.delegate = self
        window.isReleasedWhenClosed = false

        let contentView = loadMediaView() ?? createFallbackView()
        window.contentView = contentView

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    /// プログラムからの終了（入力検知時）
    func dismiss() {
        window?.delegate = nil
        stopPlayback()
        window?.close()
        window = nil
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        stopPlayback()
        window = nil
        onDismiss?()
    }

    // MARK: - Playback Control

    private func stopPlayback() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
        player?.pause()
        player = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - Media Loading

    private func loadMediaView() -> NSView? {
        let mediaDir = Config.mediaDirectoryURL

        guard FileManager.default.fileExists(atPath: mediaDir.path) else { return nil }

        let contents = (try? FileManager.default.contentsOfDirectory(
            at: mediaDir,
            includingPropertiesForKeys: nil
        )) ?? []

        // 動画ファイルを優先
        let videos = contents.filter {
            Config.videoExtensions.contains($0.pathExtension.lowercased())
        }
        if let video = videos.randomElement() {
            return createVideoView(url: video)
        }

        // 画像＋音声
        let images = contents.filter {
            Config.imageExtensions.contains($0.pathExtension.lowercased())
        }
        if let image = images.randomElement() {
            let audios = contents.filter {
                Config.audioExtensions.contains($0.pathExtension.lowercased())
            }
            return createImageAudioView(imageURL: image, audioURL: audios.randomElement())
        }

        // 音声のみ
        let audios = contents.filter {
            Config.audioExtensions.contains($0.pathExtension.lowercased())
        }
        if let audio = audios.randomElement() {
            playAudio(url: audio)
            return nil // フォールバックViewを使用
        }

        return nil
    }

    // MARK: - Video

    private func createVideoView(url: URL) -> NSView {
        let container = NSView(
            frame: NSRect(x: 0, y: 0, width: Config.windowWidth, height: Config.windowHeight)
        )

        let player = AVPlayer(url: url)
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.frame = container.bounds
        playerView.autoresizingMask = [.width, .height]
        container.addSubview(playerView)

        // テキストオーバーレイ
        let overlay = createOverlayLabel()
        container.addSubview(overlay)

        // ループ再生
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }

        player.play()
        self.player = player
        return container
    }

    // MARK: - Image + Audio

    private func createImageAudioView(imageURL: URL, audioURL: URL?) -> NSView {
        let container = NSView(
            frame: NSRect(x: 0, y: 0, width: Config.windowWidth, height: Config.windowHeight)
        )
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.black.cgColor

        if let image = NSImage(contentsOf: imageURL) {
            let imageView = NSImageView(frame: container.bounds)
            imageView.image = image
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.autoresizingMask = [.width, .height]
            container.addSubview(imageView)
        }

        // テキストオーバーレイ
        let overlay = createOverlayLabel()
        container.addSubview(overlay)

        if let audioURL = audioURL {
            playAudio(url: audioURL)
        }

        return container
    }

    private func createOverlayLabel() -> NSTextField {
        let label = NSTextField(labelWithString: Config.overlayMessage)
        label.font = NSFont.systemFont(ofSize: 36, weight: .heavy)
        label.textColor = .white
        label.alignment = .center
        label.wantsLayer = true
        label.shadow = {
            let s = NSShadow()
            s.shadowColor = NSColor.black.withAlphaComponent(0.8)
            s.shadowBlurRadius = 6
            s.shadowOffset = NSSize(width: 0, height: -2)
            return s
        }()
        label.sizeToFit()
        label.frame = NSRect(
            x: 0,
            y: 20,
            width: Config.windowWidth,
            height: label.frame.height
        )
        return label
    }

    private func playAudio(url: URL) {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = -1 // ループ再生
            audioPlayer.play()
            self.audioPlayer = audioPlayer
        } catch {
            // 音声再生失敗は無視（視覚刺激のみで続行）
        }
    }

    // MARK: - Fallback View

    private func createFallbackView() -> NSView {
        let container = NSView(
            frame: NSRect(x: 0, y: 0, width: Config.windowWidth, height: Config.windowHeight)
        )
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(
            red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0
        ).cgColor

        // メインメッセージ
        let mainLabel = NSTextField(labelWithString: "何やってるんですか仕事してください")
        mainLabel.font = NSFont.systemFont(ofSize: 48, weight: .bold)
        mainLabel.textColor = .white
        mainLabel.alignment = .center
        mainLabel.sizeToFit()
        mainLabel.frame.origin = NSPoint(
            x: (Config.windowWidth - mainLabel.frame.width) / 2,
            y: (Config.windowHeight - mainLabel.frame.height) / 2 + 20
        )
        container.addSubview(mainLabel)

        // サブメッセージ
        let subLabel = NSTextField(labelWithString: "キーボードかマウスを操作すると閉じます")
        subLabel.font = NSFont.systemFont(ofSize: 16, weight: .regular)
        subLabel.textColor = NSColor(white: 0.5, alpha: 1.0)
        subLabel.alignment = .center
        subLabel.sizeToFit()
        subLabel.frame.origin = NSPoint(
            x: (Config.windowWidth - subLabel.frame.width) / 2,
            y: mainLabel.frame.origin.y - 40
        )
        container.addSubview(subLabel)

        // システム音で聴覚刺激
        NSSound(named: "Funk")?.play()

        return container
    }
}
