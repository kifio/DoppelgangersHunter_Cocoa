//
//  ContentViewController.swift
//  DoppelgangersHunter-Cocoa
//
//  Created by imurashov on 24.12.2025.
//

import AppKit
import AVKit
import DoppelgangersHunter

protocol FileContentView {
    func show(doppelganger: Doppelganger?)
}

final class ContentViewController: NSViewController {

    private var player: AVPlayer?
    private var lastOpenedTextURL: URL?

    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        player?.pause()
    }

    private func loadContent(for doppelganger: Doppelganger) {
        let url = URL(fileURLWithPath: doppelganger.path)
        switch doppelganger.contentType {
        case .image:
            showImage(url: url)
        case .video:
            showVideo(url: url)
        case .unpreviewable:
            showText(url: url)
        }
    }

    private func pinToEdges(_ subview: NSView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)
        subview.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subview.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        subview.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subview.setContentHuggingPriority(.defaultLow, for: .vertical)
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 4),
            subview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 4),
            subview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            subview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 4),
        ])
    }

    private func showImage(url: URL) {
        guard let image = NSImage(contentsOf: url) else { showUnsupported(); return }
        let imageView = NSImageView(image: image)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        imageView.isEditable = false
        pinToEdges(imageView)
    }

    private func showVideo(url: URL) {
        let playerView = AVPlayerView()
        let player = AVPlayer(url: url)
        self.player = player
        playerView.player = player
        playerView.controlsStyle = .floating
        pinToEdges(playerView)
        player.play()
    }

    private func showText(url: URL) {
        self.lastOpenedTextURL = url
        if
            let data = try? Data(contentsOf: url),
            let string = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16)
        {
            showTextFileContent(content: string)
        } else if let string = try? String(contentsOf: url, encoding: .utf8) {
            showTextFileContent(content: string)
        } else {
            showUnsupported()
        }
    }
    
    private func showTextFileContent(content: String) {
        let textView = makeTextView(with: content)
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.leadingAnchor, constant: 4),
            textView.trailingAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.trailingAnchor, constant: 4),
            textView.topAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: 4),
            textView.bottomAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor, constant: 4),
        ])
        pinToEdges(scrollView)
    }

    private func showUnsupported() {
        let textView = makeTextView(
            with:  NSLocalizedString("content.unavailable", comment: ""),
            of: NSFont.boldSystemFont(ofSize: 24),
            alignment: .center
        )
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.distribution = .fill
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        let button = NSButton(
            title: NSLocalizedString("content.open", comment: ""),
            target: nil,
            action: nil
        )
        button.setButtonType(.momentaryPushIn)
        button.bezelStyle = .glass
        button.action = #selector(openFileExternally)
        button.target = self
        stack.addArrangedSubview(textView)
        stack.addArrangedSubview(button)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalToConstant: 320),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func makeTextView(
        with text: String,
        of font: NSFont = NSFont.systemFont(ofSize: 14),
        alignment: NSTextAlignment = .natural
    ) -> NSTextView {
        let textView = NSTextView(frame: .zero)
        textView.string = text
        textView.alignment = alignment
        textView.font = font
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = true
        textView.usesFontPanel = true
        textView.allowsUndo = true
        textView.textContainer?.widthTracksTextView = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }
    
    @objc private func openFileExternally() {
        if let url = lastOpenedTextURL {
            NSWorkspace.shared.open(url)
        }
    }
}

extension ContentViewController: FileContentView {
    func show(doppelganger: DoppelgangersHunter.Doppelganger?) {
        player = nil
        view.subviews.removeAll()
        if let doppelganger {
            loadContent(for: doppelganger)
        }
    }
}
